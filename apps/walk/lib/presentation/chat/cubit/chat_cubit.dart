import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/chat_settings.dart';
import '../../../domain/chat/usecase/chat_session.dart';
import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import 'chat_state.dart';

/// 채팅 탭 상태. 질문 하나에 user 말풍선과 흘러나오는 assistant 말풍선 하나를 붙인다.
///
/// 대화는 [ChatSession](싱글턴)이 들고, 이 cubit 은 화면에 보일 말풍선만 들고 있다.
/// 탭이 소유한다(잠금 게이트 바깥) — 다시 잠겼다 풀려도 대화가 남는다.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._session, this._settings, this._diary)
    : super(const ChatState(access: ChatAccess.checking));

  final ChatSession _session;
  final ChatSettings _settings;
  final DiaryRepository _diary;

  StreamSubscription<ChatEvent>? _sub;
  Completer<void>? _running;

  /// 지금 질문의 끝(ChatFinished)을 받아 인용을 읽는 중.
  bool _finishing = false;

  /// [newConversation] 마다 올린다. 끊긴 질문의 늦은 결과(인용 읽기)를 버린다.
  int _generation = 0;

  /// 키 · 동의 상태를 다시 읽는다. 탭이 보이게 될 때 부른다.
  Future<void> refresh() async {
    final key = await _settings.apiKey();
    if (isClosed) return;
    final access = switch ((key, _settings.consented)) {
      (null, _) => ChatAccess.noKey,
      (_, false) => ChatAccess.needsConsent,
      _ => ChatAccess.ready,
    };
    emit(state.copyWith(access: access));
  }

  Future<void> consent() async {
    await _settings.setConsented();
    await refresh();
  }

  /// 질문을 보낸다. 빈 질문이거나 답하는 중이면 무시한다.
  /// 돌려주는 Future 는 답이 끝나거나(성공 · 실패) [newConversation] 으로 끊길 때 끝난다.
  Future<void> send(String question) {
    final text = question.trim();
    if (text.isEmpty || state.busy) return Future.value();
    final Stream<ChatEvent> events;
    try {
      events = _session.ask(text);
    } on StateError {
      // 세션이 아직 이전 질문을 돌리는 중 — 이 cubit 이 모르는 질문이다. 보내지 않는다.
      return Future.value();
    }
    final generation = _generation;
    final running = _running = Completer<void>();
    _finishing = false;
    emit(
      state.copyWith(
        bubbles: [
          ...state.bubbles,
          ChatBubble(role: ChatRole.user, text: text),
          const ChatBubble(role: ChatRole.assistant, text: ''),
        ],
        busy: true,
        activeTool: null,
      ),
    );
    _sub = events.listen(
      (event) => unawaited(_onEvent(event, generation)),
      onError: (Object _) => _fail(ChatFailure.unknown, generation),
      onDone: () => _settle(generation),
    );
    return running.future;
  }

  /// 대화를 비운다. 답하는 중이면 끊는다 — 세션은 그 질문의 이벤트를 더 내지 않는다.
  void newConversation() {
    _generation++;
    unawaited(_sub?.cancel());
    _sub = null;
    _session.reset();
    _complete();
    emit(state.copyWith(bubbles: const [], busy: false, activeTool: null));
  }

  Future<void> _onEvent(ChatEvent event, int generation) async {
    if (generation != _generation || isClosed) return;
    switch (event) {
      case ChatText(:final delta):
        emit(
          state.copyWith(
            bubbles: _withLast((b) => b.copyWith(text: b.text + delta)),
            activeTool: null,
          ),
        );
      case ChatToolStarted(:final toolName):
        emit(state.copyWith(activeTool: toolName));
      case ChatFinished(:final citedEntryIds):
        _finishing = true;
        final cited = await _resolve(citedEntryIds);
        if (generation != _generation || isClosed) return;
        _end(_withLast((b) => b.copyWith(cited: cited)));
      case ChatFailed(:final failure):
        _fail(failure, generation);
    }
  }

  void _fail(ChatFailure failure, int generation) {
    if (generation != _generation || isClosed) return;
    _end(_withLast((b) => b.copyWith(failure: failure)));
  }

  /// 끝 이벤트 없이 스트림이 닫혔다(세션이 조용히 멈춤). 인용을 읽는 중이면 그쪽이 끝낸다.
  void _settle(int generation) {
    if (generation != _generation || isClosed) return;
    if (state.busy && !_finishing) _end(state.bubbles);
  }

  void _end(List<ChatBubble> bubbles) {
    emit(state.copyWith(bubbles: bubbles, busy: false, activeTool: null));
    _complete();
  }

  /// 인용 id 를 기록으로. 휴지통 · 없는 기록 · 읽기 실패는 뺀다.
  Future<List<DiaryEntry>> _resolve(List<String> ids) async {
    final entries = <DiaryEntry>[];
    for (final id in ids) {
      try {
        if (await _diary.entry(id) case Ok(
          :final value,
        ) when !value.isTrashed) {
          entries.add(value);
        }
      } on Object {
        // 한 기록을 못 읽어도 답은 보인다.
      }
    }
    return entries;
  }

  /// 마지막(assistant) 말풍선만 바꾼 목록.
  List<ChatBubble> _withLast(ChatBubble Function(ChatBubble) update) {
    final bubbles = state.bubbles;
    if (bubbles.isEmpty) return bubbles;
    return [...bubbles.sublist(0, bubbles.length - 1), update(bubbles.last)];
  }

  void _complete() {
    final running = _running;
    _running = null;
    if (running != null && !running.isCompleted) running.complete();
  }

  @override
  Future<void> close() async {
    _generation++;
    // 기다리지 않는다 — 응답을 기다리는 중인 세션 스트림은 취소가 늦게 끝날 수 있다.
    unawaited(_sub?.cancel());
    _complete();
    return super.close();
  }
}
