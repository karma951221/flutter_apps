import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/chat_policy.dart';
import '../../domain/entity/chat_image_draft.dart';
import '../../domain/entity/chat_message.dart';
import '../../domain/usecase/chat_use_case.dart';
import 'chat_room_event.dart';
import 'chat_room_state.dart';

/// 한 방의 메시지 목록과 전송을 소유한다.
///
/// 이 화면이 Bloc 인 이유는 이벤트가 여럿이기 때문이다 — 전송 · 수신 · 위로 더
/// 읽기 · 읽음 · 재전송 · 삭제 (아키텍처 §4).
@injectable
class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  ChatRoomBloc(this._useCase) : super(const ChatRoomState()) {
    on<ChatRoomStarted>(_onStarted);
    on<ChatRoomMessageReceived>(_onMessageReceived);
    on<ChatRoomSendRequested>(_onSendRequested);
    on<ChatRoomImageSendRequested>(_onImageSendRequested);
    on<ChatRoomRetryRequested>(_onRetryRequested);
    on<ChatRoomMoreRequested>(_onMoreRequested);
    on<ChatRoomDeleteRequested>(_onDeleteRequested);
    on<ChatRoomParticipantsRefreshed>(_onParticipantsRefreshed);
    on<ChatRoomReadConfirmed>(_onReadConfirmed);
  }

  /// 읽음 갱신을 모아 보내는 간격. 메시지가 쏟아질 때 갱신도 같이 쏟아지지
  /// 않게 한다.
  static const markReadDebounce = Duration(seconds: 2);

  final ChatUseCase _useCase;

  StreamSubscription<ChatMessage>? _subscription;
  Timer? _markReadTimer;

  /// 낙관적으로 띄운 뒤 아직 확정되지 않은 버블의 원문. 재전송이 이걸 쓴다.
  final _pendingText = <String, String>{};
  final _pendingImages = <String, ChatImageDraft>{};

  Future<void> _onStarted(
    ChatRoomStarted event,
    Emitter<ChatRoomState> emit,
  ) async {
    // 구독을 히스토리보다 **먼저** 건다. 반대로 하면 읽는 동안 도착한 메시지가
    // 두 경로 어디에도 들어오지 않아 조용히 사라진다.
    await _subscription?.cancel();
    _subscription = _useCase
        .messageStream(event.roomId)
        .listen(
          (message) => add(ChatRoomEvent.messageReceived(message)),
          // 구독이 끊겨도 화면을 죽이지 않는다. 이미 읽은 메시지는 그대로 두고
          // 다시 열 때 히스토리로 메운다.
          onError: (_) {},
        );

    final participants = await _useCase.getParticipants(event.roomId);
    final nicknames = participants.when(
      ok: (rows) => {for (final row in rows) row.userId: row.nickname},
      err: (_) => <String, String>{},
    );

    final result = await _useCase.getMessages(
      roomId: event.roomId,
      limit: ChatPolicy.messagePageSize,
    );

    emit(
      result.when(
        ok: (page) => ChatRoomState(
          status: ChatRoomStatus.loaded,
          roomId: event.roomId,
          messages: _withNicknames(page.items, nicknames),
          participantNicknames: nicknames,
          nextCursor: page.nextCursor,
        ),
        err: (failure) => ChatRoomState(
          status: ChatRoomStatus.failure,
          roomId: event.roomId,
          participantNicknames: nicknames,
          failure: failure,
        ),
      ),
    );

    if (state.status == ChatRoomStatus.loaded) _scheduleMarkRead();
  }

  Future<void> _onMessageReceived(
    ChatRoomMessageReceived event,
    Emitter<ChatRoomState> emit,
  ) async {
    final incoming = event.message;

    // 내가 방금 보낸 것이 되돌아왔다. 낙관적 버블을 확정으로 바꾼다 —
    // 새로 붙이면 같은 메시지가 두 번 보인다.
    final existing = state.messages.indexWhere((m) => m.id == incoming.id);
    if (existing >= 0) {
      _pendingText.remove(incoming.id);
      _pendingImages.remove(incoming.id);
      final next = [...state.messages];
      next[existing] = incoming.withSenderNickname(
        state.participantNicknames[incoming.senderId],
      );
      emit(_copyWithMessages(next));
      return;
    }

    final sender = incoming.senderId;
    // 내가 참여자 목록을 읽은 뒤에 들어온 사람이다. 이름 없이 그리지 않도록
    // 목록을 다시 읽는다.
    if (sender != null && !state.participantNicknames.containsKey(sender)) {
      add(const ChatRoomEvent.participantsRefreshed());
    }

    emit(
      _copyWithMessages([
        incoming.withSenderNickname(state.participantNicknames[sender]),
        ...state.messages,
      ]),
    );
    _scheduleMarkRead();
  }

  Future<void> _onSendRequested(
    ChatRoomSendRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty) return;

    final id = _useCase.newMessageId();
    _pendingText[id] = text;
    emit(_copyWithMessages([_optimisticText(id, text), ...state.messages]));

    await _send(id, emit);
  }

  Future<void> _onImageSendRequested(
    ChatRoomImageSendRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    final id = _useCase.newMessageId();
    _pendingImages[id] = event.image;
    emit(_copyWithMessages([_optimisticImage(id), ...state.messages]));

    await _send(id, emit);
  }

  Future<void> _onRetryRequested(
    ChatRoomRetryRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    final index = state.messages.indexWhere((m) => m.id == event.messageId);
    if (index < 0 || !state.messages[index].isFailed) return;

    final next = [...state.messages];
    next[index] = next[index].withDelivery(ChatMessageDelivery.pending);
    emit(_copyWithMessages(next));

    await _send(event.messageId, emit);
  }

  /// 전송의 공통 꼬리. 성공하면 버블은 실시간 페이로드가 확정하고, 실패하면
  /// 여기서 실패 표시를 남긴다.
  Future<void> _send(String id, Emitter<ChatRoomState> emit) async {
    final text = _pendingText[id];
    final image = _pendingImages[id];

    final result = text != null
        ? await _useCase.sendMessage(
            id: id,
            roomId: state.roomId,
            content: text,
          )
        : await _useCase.sendImageMessage(
            id: id,
            roomId: state.roomId,
            image: image!,
          );

    result.when(
      // 확정은 실시간이 한다. 여기서 sent 로 바꾸면 구독이 끊긴 상태에서도
      // 보낸 것처럼 보이게 되어 거짓이 된다.
      ok: (_) {},
      err: (failure) {
        final index = state.messages.indexWhere((m) => m.id == id);
        if (index < 0) return;
        final next = [...state.messages];
        next[index] = next[index].withDelivery(ChatMessageDelivery.failed);
        emit(_copyWithMessages(next, actionFailure: failure));
      },
    );
  }

  Future<void> _onMoreRequested(
    ChatRoomMoreRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (state.status != ChatRoomStatus.loaded ||
        state.isLoadingMore ||
        !state.canLoadMore) {
      return;
    }

    emit(_copyWithMessages(state.messages, isLoadingMore: true));

    final result = await _useCase.getMessages(
      roomId: state.roomId,
      limit: ChatPolicy.messagePageSize,
      cursor: state.nextCursor,
    );

    emit(
      result.when(
        // 오래된 페이지는 **뒤에** 붙는다. 목록이 최신순이기 때문이다.
        ok: (page) => _copyWithMessages(
          [
            ...state.messages,
            ..._withNicknames(page.items, state.participantNicknames),
          ],
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
        ),
        // 실패해도 읽은 목록과 커서를 지우지 않는다. 다시 시도할 수 있다.
        err: (failure) =>
            _copyWithMessages(state.messages, actionFailure: failure),
      ),
    );
  }

  Future<void> _onDeleteRequested(
    ChatRoomDeleteRequested event,
    Emitter<ChatRoomState> emit,
  ) async {
    final result = await _useCase.deleteMessage(event.messageId);

    emit(
      result.when(
        ok: (deleted) => deleted
            // 소프트 삭제는 조회에서 사라지는 것이라 화면에서도 걷어낸다.
            // 게시물·댓글과 달리 "삭제됨" 자리를 남기지 않는다 — 대화는
            // 흐름이라 빈 자리가 더 어수선하다.
            ? _copyWithMessages(
                state.messages
                    .where((m) => m.id != event.messageId)
                    .toList(),
              )
            : _copyWithMessages(state.messages),
        err: (failure) =>
            _copyWithMessages(state.messages, actionFailure: failure),
      ),
    );
  }

  Future<void> _onParticipantsRefreshed(
    ChatRoomParticipantsRefreshed event,
    Emitter<ChatRoomState> emit,
  ) async {
    final result = await _useCase.getParticipants(state.roomId);

    result.when(
      ok: (rows) {
        final nicknames = {for (final row in rows) row.userId: row.nickname};
        emit(
          ChatRoomState(
            status: state.status,
            roomId: state.roomId,
            messages: _withNicknames(state.messages, nicknames),
            participantNicknames: nicknames,
            isLoadingMore: state.isLoadingMore,
            nextCursor: state.nextCursor,
          ),
        );
      },
      // 이름이 잠깐 비는 것은 화면이 견딘다. 조회 실패로 방을 닫지 않는다.
      err: (_) {},
    );
  }

  Future<void> _onReadConfirmed(
    ChatRoomReadConfirmed event,
    Emitter<ChatRoomState> emit,
  ) async {
    _markReadTimer?.cancel();
    await _markReadNow();
  }

  /// 디바운스한 읽음 갱신. 방을 벗어날 때 [ChatRoomReadConfirmed] 가 한 번 더
  /// 확정하므로, 마지막 몇 초가 유실되지 않는다.
  void _scheduleMarkRead() {
    _markReadTimer?.cancel();
    _markReadTimer = Timer(markReadDebounce, _markReadNow);
  }

  /// 읽음 갱신은 **소리 없이** 끝나야 한다.
  ///
  /// 디바운스 타이머가 부르는 경로라 돌려주는 Future 를 아무도 기다리지 않는다.
  /// 여기서 예외가 새면 붙잡는 곳이 없어 uncaught async error 가 되고, 화면과
  /// 무관한 실패가 앱(그리고 E2E)을 통째로 무너뜨린다 — 실제로 2026-08-28
  /// E2E 가 이것 때문에 걸렸다.
  ///
  /// 읽음 시각이 한 번 밀리는 것은 다음 갱신이 바로잡는다. 사용자에게 알릴
  /// 일도 아니다.
  Future<void> _markReadNow() async {
    if (state.roomId.isEmpty) return;
    // 목록이 최신순이라 첫 항목이 가장 최근이다. 아직 확정되지 않은 내 버블은
    // 서버에 없으므로 기준으로 삼지 않는다.
    final latest = state.messages
        .where((m) => m.delivery == ChatMessageDelivery.sent)
        .firstOrNull;
    try {
      await _useCase.markRead(
        roomId: state.roomId,
        at: latest?.createdAt ?? DateTime.now(),
      );
    } catch (_) {
      // 삼킨다. 위 주석 참고.
    }
  }

  List<ChatMessage> _withNicknames(
    List<ChatMessage> messages,
    Map<String, String> nicknames,
  ) => messages
      .map((m) => m.withSenderNickname(nicknames[m.senderId]))
      .toList();

  ChatMessage _optimisticText(String id, String text) => ChatMessage(
    id: id,
    roomId: state.roomId,
    type: ChatMessageType.text,
    createdAt: DateTime.now(),
    content: text,
    delivery: ChatMessageDelivery.pending,
  );

  ChatMessage _optimisticImage(String id) => ChatMessage(
    id: id,
    roomId: state.roomId,
    type: ChatMessageType.image,
    createdAt: DateTime.now(),
    delivery: ChatMessageDelivery.pending,
  );

  ChatRoomState _copyWithMessages(
    List<ChatMessage> messages, {
    bool isLoadingMore = false,
    String? nextCursor,
    bool clearCursor = false,
    Failure? actionFailure,
  }) => ChatRoomState(
    status: state.status,
    roomId: state.roomId,
    messages: messages,
    participantNicknames: state.participantNicknames,
    isLoadingMore: isLoadingMore,
    nextCursor: clearCursor ? null : (nextCursor ?? state.nextCursor),
    actionFailure: actionFailure,
  );

  @override
  Future<void> close() {
    _markReadTimer?.cancel();
    unawaited(_subscription?.cancel());
    // 채널을 걷어내지 않으면 방을 드나들 때마다 구독이 쌓인다.
    // 여기도 기다리는 곳이 없으므로 실패를 흘려보내면 안 된다.
    if (state.roomId.isNotEmpty) {
      unawaited(
        _useCase.disposeMessageStream(state.roomId).catchError((_) {}),
      );
    }
    return super.close();
  }
}
