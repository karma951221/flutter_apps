import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:daylog/features/chat/domain/entity/chat_image_draft.dart';
import 'package:daylog/features/chat/domain/entity/chat_message.dart';
import 'package:daylog/features/chat/domain/entity/chat_participant.dart';
import 'package:daylog/features/chat/domain/usecase/chat_use_case.dart';
import 'package:daylog/features/chat/presentation/bloc/chat_room_bloc.dart';
import 'package:daylog/features/chat/presentation/bloc/chat_room_event.dart';
import 'package:daylog/features/chat/presentation/bloc/chat_room_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatUseCase extends Mock implements ChatUseCase {}

const _roomId = 'room-1';
const _me = 'me';
const _other = 'other';

ChatMessage _text(
  String id, {
  String senderId = _other,
  String content = '안녕',
  int minute = 0,
}) => ChatMessage(
  id: id,
  roomId: _roomId,
  type: ChatMessageType.text,
  createdAt: DateTime.utc(2026, 8, 28, 10, minute),
  senderId: senderId,
  content: content,
);

void main() {
  late _MockChatUseCase useCase;
  late StreamController<ChatMessage> incoming;
  var nextId = 0;

  setUpAll(() {
    registerFallbackValue(
      ChatImageDraft(
        bytes: Uint8List(0),
        contentType: 'image/webp',
        extension: 'webp',
      ),
    );
  });

  setUp(() {
    useCase = _MockChatUseCase();
    incoming = StreamController<ChatMessage>.broadcast();
    nextId = 0;

    when(() => useCase.messageStream(any())).thenAnswer((_) => incoming.stream);
    when(() => useCase.disposeMessageStream(any())).thenAnswer((_) async {});
    when(() => useCase.newMessageId()).thenAnswer((_) => 'new-${++nextId}');
    when(() => useCase.getParticipants(any())).thenAnswer(
      (_) async => Ok([
        ChatParticipant(
          userId: _other,
          nickname: '상대',
          joinedAt: DateTime.utc(2026, 8, 28),
        ),
      ]),
    );
    when(
      () => useCase.getMessages(
        roomId: any(named: 'roomId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => Ok(CursorPage(items: [_text('old')])));
    when(
      () => useCase.sendMessage(
        id: any(named: 'id'),
        roomId: any(named: 'roomId'),
        content: any(named: 'content'),
      ),
    ).thenAnswer((_) async => const Ok(null));
    when(
      () => useCase.sendImageMessage(
        id: any(named: 'id'),
        roomId: any(named: 'roomId'),
        image: any(named: 'image'),
      ),
    ).thenAnswer((_) async => const Ok(null));
    when(
      () => useCase.markRead(
        roomId: any(named: 'roomId'),
        at: any(named: 'at'),
      ),
    ).thenAnswer((_) async => const Ok(null));
    when(
      () => useCase.deleteMessage(any()),
    ).thenAnswer((_) async => const Ok(true));
  });

  tearDown(() => incoming.close());

  ChatRoomBloc build() => ChatRoomBloc(useCase);

  blocTest<ChatRoomBloc, ChatRoomState>(
    '방을 열면 히스토리를 읽고 방별 닉네임을 붙인다',
    build: build,
    act: (bloc) => bloc.add(const ChatRoomEvent.started(_roomId)),
    verify: (bloc) {
      expect(bloc.state.status, ChatRoomStatus.loaded);
      expect(bloc.state.messages.single.senderNickname, '상대');
    },
  );

  blocTest<ChatRoomBloc, ChatRoomState>(
    '구독을 히스토리보다 먼저 건다',
    build: build,
    act: (bloc) => bloc.add(const ChatRoomEvent.started(_roomId)),
    verify: (_) {
      // 순서가 반대면 읽는 동안 도착한 메시지가 두 경로 어디에도 들어오지 않는다.
      verifyInOrder([
        () => useCase.messageStream(_roomId),
        () => useCase.getMessages(
          roomId: _roomId,
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ]);
    },
  );

  blocTest<ChatRoomBloc, ChatRoomState>(
    '보내면 버블이 pending 으로 즉시 뜬다',
    build: build,
    act: (bloc) async {
      bloc.add(const ChatRoomEvent.started(_roomId));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ChatRoomEvent.sendRequested('반가워'));
    },
    wait: const Duration(milliseconds: 20),
    verify: (bloc) {
      final bubble = bloc.state.messages.first;
      expect(bubble.content, '반가워');
      expect(bubble.delivery, ChatMessageDelivery.pending);
      expect(bubble.id, 'new-1');
    },
  );

  blocTest<ChatRoomBloc, ChatRoomState>(
    '실시간으로 되돌아온 내 메시지는 중복되지 않고 확정된다',
    build: build,
    act: (bloc) async {
      bloc.add(const ChatRoomEvent.started(_roomId));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ChatRoomEvent.sendRequested('반가워'));
      await Future<void>.delayed(Duration.zero);
      // 서버가 같은 id 로 돌려준다 — 앱이 id 를 먼저 만들었기 때문이다.
      incoming.add(_text('new-1', senderId: _me, content: '반가워', minute: 1));
    },
    wait: const Duration(milliseconds: 20),
    verify: (bloc) {
      final mine = bloc.state.messages.where((m) => m.id == 'new-1');
      expect(mine.length, 1);
      expect(mine.single.delivery, ChatMessageDelivery.sent);
    },
  );

  blocTest<ChatRoomBloc, ChatRoomState>(
    '전송이 실패하면 버블이 failed 로 남는다',
    build: () {
      when(
        () => useCase.sendMessage(
          id: any(named: 'id'),
          roomId: any(named: 'roomId'),
          content: any(named: 'content'),
        ),
      ).thenAnswer((_) async => const Err(Failure.network()));
      return build();
    },
    act: (bloc) async {
      bloc.add(const ChatRoomEvent.started(_roomId));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ChatRoomEvent.sendRequested('반가워'));
    },
    wait: const Duration(milliseconds: 20),
    verify: (bloc) {
      expect(bloc.state.messages.first.delivery, ChatMessageDelivery.failed);
      expect(bloc.state.actionFailure, isA<NetworkFailure>());
    },
  );

  blocTest<ChatRoomBloc, ChatRoomState>(
    '재전송하면 같은 id 로 다시 보낸다',
    build: () {
      var attempts = 0;
      when(
        () => useCase.sendMessage(
          id: any(named: 'id'),
          roomId: any(named: 'roomId'),
          content: any(named: 'content'),
        ),
      ).thenAnswer((_) async {
        attempts++;
        return attempts == 1 ? const Err(Failure.network()) : const Ok(null);
      });
      return build();
    },
    act: (bloc) async {
      bloc.add(const ChatRoomEvent.started(_roomId));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ChatRoomEvent.sendRequested('반가워'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const ChatRoomEvent.retryRequested('new-1'));
    },
    wait: const Duration(milliseconds: 30),
    verify: (bloc) {
      // 새 id 를 만들지 않는다 — 만들면 서버에 두 벌이 생긴다.
      verify(() => useCase.newMessageId()).called(1);
      verify(
        () => useCase.sendMessage(id: 'new-1', roomId: _roomId, content: '반가워'),
      ).called(2);
      expect(bloc.state.messages.first.delivery, ChatMessageDelivery.pending);
    },
  );

  blocTest<ChatRoomBloc, ChatRoomState>(
    '받은 메시지는 목록 앞(= 화면 아래)에 붙는다',
    build: build,
    act: (bloc) async {
      bloc.add(const ChatRoomEvent.started(_roomId));
      await Future<void>.delayed(Duration.zero);
      incoming.add(_text('fresh', minute: 5));
    },
    wait: const Duration(milliseconds: 20),
    verify: (bloc) {
      expect(bloc.state.messages.first.id, 'fresh');
      expect(bloc.state.messages.last.id, 'old');
    },
  );

  blocTest<ChatRoomBloc, ChatRoomState>(
    '모르는 사람의 메시지가 오면 참여자 목록을 다시 읽는다',
    build: build,
    act: (bloc) async {
      bloc.add(const ChatRoomEvent.started(_roomId));
      await Future<void>.delayed(Duration.zero);
      when(() => useCase.getParticipants(any())).thenAnswer(
        (_) async => Ok([
          ChatParticipant(
            userId: _other,
            nickname: '상대',
            joinedAt: DateTime.utc(2026, 8, 28),
          ),
          ChatParticipant(
            userId: 'newcomer',
            nickname: '새사람',
            joinedAt: DateTime.utc(2026, 8, 28),
          ),
        ]),
      );
      incoming.add(_text('n1', senderId: 'newcomer', minute: 6));
    },
    wait: const Duration(milliseconds: 30),
    verify: (bloc) {
      verify(() => useCase.getParticipants(_roomId)).called(2);
      expect(bloc.state.participantNicknames['newcomer'], '새사람');
      expect(
        bloc.state.messages.firstWhere((m) => m.id == 'n1').senderNickname,
        '새사람',
      );
    },
  );

  blocTest<ChatRoomBloc, ChatRoomState>(
    '위로 더 읽으면 오래된 페이지가 뒤에 붙는다',
    build: () {
      when(
        () => useCase.getMessages(
          roomId: any(named: 'roomId'),
          limit: any(named: 'limit'),
          cursor: null,
        ),
      ).thenAnswer(
        (_) async =>
            Ok(CursorPage(items: [_text('p1', minute: 9)], nextCursor: 'c1')),
      );
      when(
        () => useCase.getMessages(
          roomId: any(named: 'roomId'),
          limit: any(named: 'limit'),
          cursor: 'c1',
        ),
      ).thenAnswer(
        (_) async => Ok(CursorPage(items: [_text('p2', minute: 1)])),
      );
      return build();
    },
    act: (bloc) async {
      bloc.add(const ChatRoomEvent.started(_roomId));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ChatRoomEvent.moreRequested());
    },
    wait: const Duration(milliseconds: 20),
    verify: (bloc) {
      expect(bloc.state.messages.map((m) => m.id), ['p1', 'p2']);
      expect(bloc.state.canLoadMore, isFalse);
    },
  );

  blocTest<ChatRoomBloc, ChatRoomState>(
    '삭제하면 목록에서 걷어낸다',
    build: build,
    act: (bloc) async {
      bloc.add(const ChatRoomEvent.started(_roomId));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ChatRoomEvent.deleteRequested('old'));
    },
    wait: const Duration(milliseconds: 20),
    verify: (bloc) => expect(bloc.state.messages, isEmpty),
  );

  blocTest<ChatRoomBloc, ChatRoomState>(
    '지운 것이 없으면 목록을 건드리지 않는다',
    build: () {
      when(
        () => useCase.deleteMessage(any()),
      ).thenAnswer((_) async => const Ok(false));
      return build();
    },
    act: (bloc) async {
      bloc.add(const ChatRoomEvent.started(_roomId));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ChatRoomEvent.deleteRequested('old'));
    },
    wait: const Duration(milliseconds: 20),
    verify: (bloc) => expect(bloc.state.messages.single.id, 'old'),
  );

  blocTest<ChatRoomBloc, ChatRoomState>(
    '나갈 때 읽음을 확정한다 — 마지막으로 확정된 메시지 시각으로',
    build: build,
    act: (bloc) async {
      bloc.add(const ChatRoomEvent.started(_roomId));
      await Future<void>.delayed(Duration.zero);
      // 아직 서버에 없는 내 버블은 기준이 되면 안 된다.
      bloc.add(const ChatRoomEvent.sendRequested('보내는 중'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ChatRoomEvent.readConfirmed());
    },
    wait: const Duration(milliseconds: 20),
    verify: (_) {
      final at =
          verify(
                () => useCase.markRead(
                  roomId: _roomId,
                  at: captureAny(named: 'at'),
                ),
              ).captured.last
              as DateTime;
      expect(at, DateTime.utc(2026, 8, 28, 10, 0));
    },
  );

  blocTest<ChatRoomBloc, ChatRoomState>(
    '히스토리 조회에 실패하면 화면 전체가 오류가 된다',
    build: () {
      when(
        () => useCase.getMessages(
          roomId: any(named: 'roomId'),
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => const Err(Failure.network()));
      return build();
    },
    act: (bloc) => bloc.add(const ChatRoomEvent.started(_roomId)),
    verify: (bloc) {
      expect(bloc.state.status, ChatRoomStatus.failure);
      expect(bloc.state.failure, isA<NetworkFailure>());
    },
  );

  test('읽음 갱신이 실패해도 밖으로 새지 않는다', () async {
    // 디바운스 타이머가 부르는 경로라 아무도 Future 를 기다리지 않는다.
    // 예외가 새면 uncaught async error 가 되어 앱이 통째로 무너진다.
    when(
      () => useCase.markRead(
        roomId: any(named: 'roomId'),
        at: any(named: 'at'),
      ),
    ).thenThrow(StateError('read receipt exploded'));

    final bloc = build();
    addTearDown(bloc.close);
    bloc.add(const ChatRoomEvent.started(_roomId));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // 던지지 않고 조용히 지나가야 한다.
    bloc.add(const ChatRoomEvent.readConfirmed());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bloc.state.status, ChatRoomStatus.loaded);
  });

  test('닫을 때 구독과 채널을 걷어낸다', () async {
    final bloc = build();
    bloc.add(const ChatRoomEvent.started(_roomId));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await bloc.close();

    // 걷어내지 않으면 방을 드나들 때마다 구독이 쌓인다.
    verify(() => useCase.disposeMessageStream(_roomId)).called(1);
  });
}
