import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/chat_settings.dart';
import '../../../domain/chat/chat_trace.dart';
import '../../../domain/chat/usecase/chat_session.dart';
import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import 'chat_state.dart';

/// 다음 프레임이 그려진 뒤 [callback] 을 부른다.
void _addPostFrame(VoidCallback callback) =>
    SchedulerBinding.instance.addPostFrameCallback((_) => callback());

/// 채팅 탭 상태. 질문 하나에 user 말풍선과 흘러나오는 assistant 말풍선 하나를 붙인다.
///
/// 대화는 [ChatSession](싱글턴)이 들고, 이 cubit 은 화면에 보일 말풍선만 들고 있다.
/// 탭이 소유한다(잠금 게이트 바깥) — 다시 잠겼다 풀려도 대화가 남는다.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit(
    this._session,
    this._settings,
    this._diary,
    this._trace, {
    void Function(VoidCallback) schedulePostFrame = _addPostFrame,
  }) : _schedulePostFrame = schedulePostFrame,
       super(const ChatState(access: ChatAccess.checking));

  final ChatSession _session;
  final ChatSettings _settings;
  final DiaryRepository _diary;
  final ChatTrace _trace;

  /// 프레임 쪽 표시(firstVisible · firstGlyph)를 찍을 때 쓴다. 위젯은 계측을 모른다.
  final void Function(VoidCallback) _schedulePostFrame;

  // 계측 — 질문 하나 동안의 상태. trace 가 꺼져 있으면 쓰지 않는다.
  int _traceToken = 0;
  bool _tracing = false;
  bool _sawVisible = false;
  bool _sawGlyph = false;

  /// 아직 그려지지 않은 프레임 표시 수. 0 이 될 때까지 end 를 미룬다.
  int _pendingFrames = 0;

  StreamSubscription<ChatEvent>? _sub;
  Completer<void>? _running;

  /// 지금 질문의 끝(ChatFinished)을 받아 인용을 읽는 중.
  bool _finishing = false;

  /// [newConversation] · [stop] 마다 올린다. 끊긴 질문의 늦은 결과(이벤트 · 인용 읽기)를 버린다.
  int _generation = 0;

  /// 키 · 동의 상태를 다시 읽는다. 탭이 보이게 될 때 부른다.
  /// 보안 저장소를 읽지 못하면 키가 없는 것으로 본다.
  Future<void> refresh() async {
    String? key;
    try {
      key = await _settings.apiKey();
    } on Object {
      key = null;
    }
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

  /// 질문을 보낸다. 쓸 수 있는 상태(ready)가 아니거나 빈 질문이거나 답하는 중이면 무시한다.
  /// 돌려주는 Future 는 답이 끝나거나(성공 · 실패) [newConversation] 으로 끊길 때 끝난다.
  Future<void> send(String question) {
    final text = question.trim();
    if (state.access != ChatAccess.ready || text.isEmpty || state.busy) {
      return Future.value();
    }
    final Stream<ChatEvent> events;
    try {
      events = _session.ask(text);
    } on StateError {
      // 세션이 아직 이전 질문을 돌리는 중 — 이 cubit 이 모르는 질문이다. 보내지 않는다.
      return Future.value();
    }
    _traceBegin();
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
    if (state.busy) _traceDone();
    _generation++;
    unawaited(_sub?.cancel());
    _sub = null;
    _session.reset();
    _complete();
    emit(state.copyWith(bubbles: const [], busy: false, activeTool: null));
  }

  /// 답하는 중이면 멈춘다. 같은 emit 에서 busy: false. 인용을 읽는 중(_finishing)이면
  /// 무시한다(답은 이미 끝났다).
  ///
  /// 받은 글이 있으면 그 말풍선을 [ChatBubble.stopped] 로 남기고 그때까지의 인용을 붙인다.
  /// 글이 없으면 질문 · 답 말풍선을 지우고 질문을 [ChatState.restoredDraft] 로 돌려준다.
  void stop() {
    if (!state.busy || _finishing) return;
    _generation++;
    // 세션을 먼저 멈춘다 — 구독 취소를 기다린 뒤 부르면 그 사이 질문이 스스로 되돌려져
    // 받은 글을 잃는다. 취소는 기다리지 않는다(세션 루프는 stop 으로 이미 끝났다).
    final result = _session.stop();
    unawaited(_sub?.cancel());
    _sub = null;
    if (_trace.enabled && _tracing) _trace.mark(ChatTraceMark.userStop);
    switch (result) {
      case ChatStopKept(:final citedEntryIds):
        final bubbles = _withLast((b) => b.copyWith(stopped: true));
        emit(state.copyWith(bubbles: bubbles, busy: false, activeTool: null));
        if (citedEntryIds.isNotEmpty && bubbles.isNotEmpty) {
          unawaited(
            _attachCited(citedEntryIds, bubbles.length - 1, bubbles.last),
          );
        }
      case ChatStopDropped():
        final bubbles = state.bubbles;
        final question = bubbles.length >= 2
            ? bubbles[bubbles.length - 2].text
            : null;
        emit(
          state.copyWith(
            bubbles: bubbles.length >= 2
                ? bubbles.sublist(0, bubbles.length - 2)
                : const [],
            busy: false,
            activeTool: null,
            restoredDraft: question,
          ),
        );
      case ChatStopIdle():
        // 세션은 이미 끝났다 — 화면만 정리한다.
        _end(state.bubbles);
    }
    _traceDone();
    _complete();
  }

  /// 화면이 [ChatState.restoredDraft] 를 입력칸에 채웠다.
  void consumeRestoredDraft() {
    if (state.restoredDraft == null) return;
    emit(state.copyWith(restoredDraft: null));
  }

  /// 멈춘 말풍선([index] 의 [stopped])에 인용을 붙인다. 그 사이 다음 질문을 보냈어도
  /// 같은 말풍선이다. 대화를 비웠으면(그 자리에 다른 말풍선 · 없음) 버린다.
  Future<void> _attachCited(
    List<String> ids,
    int index,
    ChatBubble stopped,
  ) async {
    final cited = await _resolve(ids);
    if (isClosed) return;
    final bubbles = state.bubbles;
    if (index >= bubbles.length || !identical(bubbles[index], stopped)) return;
    emit(
      state.copyWith(
        bubbles: [
          for (final (i, b) in bubbles.indexed)
            i == index ? b.copyWith(cited: cited) : b,
        ],
      ),
    );
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
        if (_trace.enabled && delta.isNotEmpty) {
          _traceVisible();
          if (!_sawGlyph) {
            _sawGlyph = true;
            _markAfterFrame(ChatTraceMark.firstGlyph);
          }
        }
      case ChatToolStarted(:final toolName):
        emit(state.copyWith(activeTool: toolName));
        if (_trace.enabled) _traceVisible();
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
    _traceDone();
    _complete();
  }

  void _traceBegin() {
    if (!_trace.enabled) return;
    _traceToken++;
    _tracing = true;
    _sawVisible = false;
    _sawGlyph = false;
    _pendingFrames = 0;
    _trace
      ..begin()
      ..mark(ChatTraceMark.send);
  }

  void _traceVisible() {
    if (_sawVisible) return;
    _sawVisible = true;
    _markAfterFrame(ChatTraceMark.firstVisible);
  }

  /// emit 이 그려진 프레임 뒤에 찍는다. 그 사이 질문이 끝났으면 end 는 이 표시 뒤로 미뤄져 있다.
  void _markAfterFrame(String label) {
    final token = _traceToken;
    _pendingFrames++;
    _schedulePostFrame(() {
      if (token != _traceToken) return;
      _pendingFrames--;
      _trace.mark(label);
      if (!_tracing && _pendingFrames == 0) _trace.end();
    });
  }

  /// done 을 찍고, 그려지지 않은 프레임 표시가 없으면 바로 요약을 낸다.
  void _traceDone() {
    if (!_trace.enabled || !_tracing) return;
    _tracing = false;
    _trace.mark(ChatTraceMark.done);
    if (_pendingFrames == 0) _trace.end();
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
    if (state.busy) _traceDone();
    _generation++;
    // 기다리지 않는다 — 응답을 기다리는 중인 세션 스트림은 취소가 늦게 끝날 수 있다.
    unawaited(_sub?.cancel());
    // 세션은 싱글턴이다. 답하는 중에 닫혀도 다음 cubit 이 ask 할 수 있게 비운다.
    _session.reset();
    _complete();
    return super.close();
  }
}
