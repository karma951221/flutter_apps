import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/chat_settings.dart';
import '../../../domain/chat/chat_trace.dart';
import '../../../domain/chat/chat_vendor.dart';
import '../../../domain/chat/entity/conversation.dart';
import '../../../domain/chat/repository/chat_history_repository.dart';
import '../../../domain/chat/usecase/chat_model_choice.dart';
import '../../../domain/chat/usecase/chat_session.dart';
import '../../../domain/chat/usecase/open_conversation.dart';
import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../widget/model_chip.dart';
import 'chat_state.dart';

/// 다음 프레임이 그려진 뒤 [callback] 을 부른다.
void _addPostFrame(VoidCallback callback) =>
    SchedulerBinding.instance.addPostFrameCallback((_) => callback());

/// 한 대화(새 대화 · 연 대화 · 임시 대화) 동안의 저장 위치. [ChatCubit.newConversation] ·
/// [ChatCubit.open] · [ChatCubit.startTemporary] 마다 새로 만든다 — 늦게 끝난 저장이 지난
/// 대화의 것인지 이 객체로 가린다. 지난 대화 몫으로 줄 선 저장은 [id] 로 그 대화에 이어 쓴다.
class _Thread {
  _Thread({required this.temporary});

  final bool temporary;
  String? id;
}

/// 채팅 탭 상태. 질문 하나에 user 말풍선과 흘러나오는 assistant 말풍선 하나를 붙인다.
///
/// 대화는 [ChatSession](싱글턴)이 들고, 이 cubit 은 화면에 보일 말풍선만 들고 있다.
/// 탭이 소유한다(잠금 게이트 바깥) — 다시 잠겼다 풀려도 대화가 남는다.
///
/// 임시 대화가 아니면 턴이 끝날 때(답 끝 · 글이 있는 멈춤)마다 [ChatHistoryRepository] 에
/// 저장한다. 임시 대화는 저장소에 한 행도 쓰지 않는다.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit(
    this._session,
    this._settings,
    this._diary,
    this._trace,
    this._choice,
    this._history,
    this._open, {
    void Function(VoidCallback) schedulePostFrame = _addPostFrame,
  }) : _schedulePostFrame = schedulePostFrame,
       super(const ChatState(access: ChatAccess.checking));

  final ChatSession _session;
  final ChatSettings _settings;
  final DiaryRepository _diary;
  final ChatTrace _trace;

  /// 칩에 보일 지금 모델 · 탭이 열릴 때의 목록 갱신(24시간이 지났거나 · 키가 확인 전
  /// (unverified)이거나 · 목록 벤더가 연결 벤더와 다를 때만) · 사라진 모델 알림.
  final ChatModelChoice _choice;

  final ChatHistoryRepository _history;

  /// 지금 열린 저장 대화 id. 보관 정리가 이 대화를 건너뛴다.
  final OpenConversation _open;

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

  /// 지금 대화의 저장 위치.
  _Thread _thread = _Thread(temporary: false);

  /// 저장을 한 줄로 세운다 — 첫 턴이 만든 대화 id 를 다음 턴이 쓰고, seq 순서가 지켜진다.
  Future<void> _saveTail = Future.value();

  /// 지금 열린 대화가 있는지 지켜본다. 밖에서 지워지면 빈 새 대화가 된다.
  StreamSubscription<bool>? _existsSub;

  /// 진행 중인 질문 — 끝나거나 멈출 때 저장에 쓴다. [_turnTarget] 이 null 이면(모델 목록
  /// 없음) 그 질문은 noModels 로 끝나 저장하지 않는다.
  String _turnQuestion = '';
  ChatTarget? _turnTarget;

  /// 키 · 동의 · 모델 상태를 다시 읽는다. 탭이 보이게 될 때 · 위에 얹힌 화면이 걷힐 때 부른다.
  /// 보안 저장소를 읽지 못하면 키가 없는 것으로 본다.
  ///
  /// 키 · 동의가 있으면 모델을 본다(`ChatModelChoice` — 24시간 · unverified · 벤더 다름일
  /// 때만 받고, 받으면 키 상태도 기록된다).
  /// - 지금 모델이 있으면 곧바로 ready 를 내고 갱신은 뒤에서 — 끝나면 칩을 다시 읽는다.
  /// - 없으면 갱신을 기다린 뒤에도 없을 때 noModels(인증 오류면 [ChatState.modelsInvalidKey]).
  ///
  /// [recheck] 가 false 면 목록을 받지 않는다(탭이 보이지 않을 때 — 앱 시작에 다른 탭이
  /// 열려 있는 등). 그때 모델이 없으면 noModels 로 두고, 보이게 될 때 다시 부른다.
  Future<void> refresh({bool recheck = true}) =>
      _read(recheck: recheck, fetched: null);

  /// noModels 의 [다시 시도] — 목록을 강제로 받은 뒤 다시 읽는다.
  Future<void> retryModels() async {
    final result = await _choice.refresh(force: true);
    if (isClosed) return;
    await _read(recheck: false, fetched: result);
  }

  /// 모델 고르기 시트가 바꾼 뒤 칩을 다시 읽는다.
  void modelChanged() => _emitModel();

  /// 화면이 "고른 모델이 없어져…" 알림을 보였다.
  void consumeSelectionReplaced() {
    _choice.consumeSelectionReplacedNotice();
    if (state.selectionReplaced) {
      emit(state.copyWith(selectionReplaced: false));
    }
  }

  /// [fetched] 는 방금 받은 결과(retryModels) — 모델이 없어도 다시 받지 않는다.
  Future<void> _read({
    required bool recheck,
    required ModelsRefresh? fetched,
  }) async {
    bool hasKey;
    try {
      hasKey = await _settings.hasApiKey();
    } on Object {
      hasKey = false;
    }
    if (isClosed) return;
    // 동의는 벤더별 — 연결 벤더가 동의한 벤더와 다르면(벤더를 바꿨으면) 다시 묻는다.
    // 같은 벤더 키 교체 · 모델 변경은 묻지 않는다.
    final connected = _settings.connectedVendor;
    final access = switch ((hasKey, _settings.consentedVendor)) {
      (false, _) => ChatAccess.noKey,
      (_, final consented) when consented == null || consented != connected =>
        ChatAccess.needsConsent,
      _ => ChatAccess.ready,
    };
    if (access != ChatAccess.ready) {
      // 말풍선은 그대로 둔다 — 동의 뒤 ready 에서 대화를 잇는다.
      emit(
        state.copyWith(
          access: access,
          vendor: access == ChatAccess.needsConsent
              ? connected ?? _vendor()
              : _vendor(),
          model: null,
        ),
      );
      return;
    }
    if (_choice.currentModel != null) {
      _emitReady();
      if (recheck) {
        unawaited(
          Future.sync(
            _choice.refresh,
          ).then<void>((_) => _emitModel(), onError: (Object _) {}),
        );
      }
      return;
    }
    var result = fetched;
    if (result == null && recheck) {
      try {
        result = await _choice.refresh();
      } on Object {
        result = const ModelsRefresh.unreachable();
      }
      if (isClosed) return;
    }
    if (_choice.currentModel != null) {
      _emitReady();
      return;
    }
    emit(
      state.copyWith(
        access: ChatAccess.noModels,
        vendor: _vendor(),
        model: null,
        modelsInvalidKey: result is ModelsInvalidKey,
      ),
    );
  }

  void _emitReady() => emit(
    state.copyWith(
      access: ChatAccess.ready,
      vendor: _vendor(),
      model: ModelChipData.of(_choice),
      modelsInvalidKey: false,
      selectionReplaced: _choice.selectionReplacedNotice,
    ),
  );

  /// 칩 · 알림 표시를 [ChatModelChoice] 에서 다시 읽는다. ready 가 아니면 칩은 두지 않는다.
  void _emitModel() {
    if (isClosed) return;
    emit(
      state.copyWith(
        vendor: _vendor(),
        model: state.access == ChatAccess.ready
            ? ModelChipData.of(_choice)
            : null,
        selectionReplaced: _choice.selectionReplacedNotice,
      ),
    );
  }

  /// 배너 벤더 — 모델 목록이 없어도(target null) 연결 벤더로.
  ChatVendor _vendor() =>
      _session.target?.vendor ??
      _settings.connectedVendor ??
      ChatVendor.anthropic;

  /// 전송 동의 — 지금 연결된 벤더로 기록한다. 미연결이면 기록하지 않는다.
  Future<void> consent() async {
    final vendor = _settings.connectedVendor;
    if (vendor != null) await _settings.setConsented(vendor);
    await refresh();
  }

  /// 질문을 보낸다. 쓸 수 있는 상태(ready)가 아니거나 빈 질문이거나 답하는 중 · 대화를
  /// 읽어 들이는 중([ChatState.loading])이면 무시한다.
  /// 돌려주는 Future 는 답이 끝나거나(성공 · 실패) [newConversation] 으로 끊길 때 끝난다.
  /// 답이 끝났으면 그 턴의 저장 시도까지 끝난 뒤다.
  Future<void> send(String question) {
    final text = question.trim();
    if (state.access != ChatAccess.ready ||
        text.isEmpty ||
        state.busy ||
        state.loading) {
      return Future.value();
    }
    final Stream<ChatEvent> events;
    try {
      events = _session.ask(text);
    } on StateError {
      // 세션이 아직 이전 질문을 돌리는 중 — 이 cubit 이 모르는 질문이다. 보내지 않는다.
      return Future.value();
    }
    _turnQuestion = text;
    _turnTarget = _session.target;
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
  void newConversation() => _startFresh(temporary: false);

  /// 지금 대화를 닫고 빈 임시 대화를 연다. 임시 대화는 저장소에 아무것도 쓰지 않는다.
  void startTemporary() => _startFresh(temporary: true);

  /// 저장된 대화를 연다. 답하는 중이면 끊는다([newConversation] 과 같은 규칙). 임시 대화였으면
  /// 사라진다. 말풍선 · 근거 칩(휴지통 · 없는 기록 빼고) · stopped · seq 를 복원하고 세션을
  /// 그 턴들로 이어간다. 그 대화가 없으면(사이에 지워짐) 빈 새 대화.
  ///
  /// 읽는 동안 [ChatState.loading] — 그 사이 보낸 질문은 무시한다(곧 다시 그려 잃게 되므로).
  /// 읽는 동안에도 [OpenConversation.id] 는 [conversationId] 다 — 보관 정리가 건너뛰게.
  /// 줄 선 저장(지난 턴)이 끝난 뒤 읽는다 — 같은 대화를 다시 열어도 그 턴이 보이게.
  Future<void> open(String conversationId) async {
    _startFresh(temporary: false, loading: true, openId: conversationId);
    final thread = _thread;
    try {
      await _saveTail;
    } on Object {
      // 저장 실패는 _write 가 삼킨다. 여기선 읽기만 이어간다.
    }
    if (isClosed || !identical(thread, _thread)) return;
    await _load(conversationId, thread);
  }

  /// [userIndex] 의 질문과 그 답 말풍선을 지운다. 답하는 중이면 무시한다.
  ///
  /// 저장된 턴이면 저장소에서 지우고 남은 턴으로 다시 연다(남은 턴이 없으면 빈 새 대화).
  /// 임시 대화 · 저장 전 턴은 화면에서 빼고 남은 쌍으로 세션을 이어간다. 실패한 쌍은
  /// 화면에서만 뺀다(세션은 그 질문을 이미 되돌렸다).
  ///
  /// 끝날 때까지 [ChatState.loading] — 그 사이 보낸 질문은 무시한다.
  Future<void> deleteTurn(int userIndex) async {
    if (state.busy || state.loading) return;
    final target = _bubbleAt(userIndex);
    if (target == null || target.role != ChatRole.user) return;
    final thread = _thread;
    emit(state.copyWith(loading: true));
    try {
      // 줄 선 저장이 끝나야 seq 가 붙는다 — 그 뒤 같은 말풍선을 다시 찾는다.
      await _saveTail;
      if (isClosed || !identical(thread, _thread)) return;
      final index = _indexOf(target, near: userIndex);
      if (index == null) return;
      final user = state.bubbles[index];
      final answer = _bubbleAt(index + 1);
      final pairEnd = answer?.role == ChatRole.assistant
          ? index + 2
          : index + 1;
      final seq = user.seq;
      final id = state.conversationId;

      if (seq != null && id != null && !thread.temporary) {
        try {
          await _history.deleteTurn(id, seq);
        } on Object {
          return;
        }
        if (isClosed || !identical(thread, _thread)) return;
        // 새 thread 가 loading 을 이어받고 _load 가 끝에 내린다.
        _startFresh(
          temporary: false,
          keepScreen: true,
          loading: true,
          openId: id,
        );
        await _load(id, _thread);
        return;
      }

      final bubbles = [
        ...state.bubbles.sublist(0, index),
        ...state.bubbles.sublist(pairEnd),
      ];
      emit(state.copyWith(bubbles: bubbles));
      if (answer?.failure != null) return;
      _session.resume(_turnsOf(bubbles), temporary: thread.temporary);
    } finally {
      // 대화가 바뀌었으면 loading 은 새 대화의 것이다.
      if (!isClosed && identical(thread, _thread) && state.loading) {
        emit(state.copyWith(loading: false));
      }
    }
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
      case ChatStopKept(:final text, :final citedEntryIds):
        // 세션이 남긴 글이 기준이다 — 다음 문맥에 들어가는 것과 화면이 같게.
        final bubbles = _withLast((b) => b.copyWith(text: text, stopped: true));
        emit(state.copyWith(bubbles: bubbles, busy: false, activeTool: null));
        if (citedEntryIds.isNotEmpty && bubbles.isNotEmpty) {
          unawaited(
            _attachCited(
              citedEntryIds,
              bubbles.length - 1,
              bubbles.last,
              _thread,
            ),
          );
        }
        unawaited(_saveLastTurn(citedEntryIds, stopped: true));
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
  /// 같은 말풍선이다. 대화를 바꿨거나([thread]) 비웠으면(그 자리에 다른 말풍선 · 없음) 버린다.
  Future<void> _attachCited(
    List<String> ids,
    int index,
    ChatBubble stopped,
    _Thread thread,
  ) async {
    final cited = await _resolve(ids);
    if (isClosed || !identical(thread, _thread)) return;
    final bubbles = state.bubbles;
    if (index >= bubbles.length || !_same(bubbles[index], stopped)) return;
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
      case ChatToolStarted(:final name):
        emit(state.copyWith(activeTool: name));
        if (_trace.enabled) _traceVisible();
      // 진행 줄은 다음 단계(Task 5)에서 그린다 — 지금은 무시.
      case ChatPhaseChanged() ||
          ChatProgressNote() ||
          ChatToolFinished() ||
          ChatRoundStarted():
        break;
      case ChatFinished(:final citedEntryIds):
        _finishing = true;
        final running = _running;
        // 인용을 읽기 전에 지금 대화(thread)로 저장을 줄 세운다 — 읽는 사이 [새 대화] · open 해도
        // 끝난 답은 저장된다(화면에 붙일지는 _write 가 thread 로 가린다).
        final saved = _saveLastTurn(citedEntryIds, stopped: false);
        final cited = await _resolve(citedEntryIds);
        if (generation != _generation || isClosed) return;
        _end(_withLast((b) => b.copyWith(cited: cited)), complete: false);
        // send 의 Future 는 저장 시도까지 끝난 뒤에 끝난다.
        await saved;
        if (running != null && !running.isCompleted) running.complete();
        if (identical(_running, running)) _running = null;
      case ChatFailed(:final failure):
        _fail(failure, generation);
    }
  }

  void _fail(ChatFailure failure, int generation) {
    if (generation != _generation || isClosed) return;
    _end(_withLast((b) => b.copyWith(failure: failure)));
    // 세션이 목록을 다시 받아 지금 모델이 바뀌었다 — 칩도 새 모델로.
    if (failure == ChatFailure.modelReplaced) _emitModel();
  }

  /// 끝 이벤트 없이 스트림이 닫혔다(세션이 조용히 멈춤). 인용을 읽는 중이면 그쪽이 끝낸다.
  void _settle(int generation) {
    if (generation != _generation || isClosed) return;
    if (state.busy && !_finishing) _end(state.bubbles);
  }

  void _end(List<ChatBubble> bubbles, {bool complete = true}) {
    emit(state.copyWith(bubbles: bubbles, busy: false, activeTool: null));
    _traceDone();
    if (complete) _complete();
  }

  /// 대화를 끊고 빈 새 대화(또는 임시 대화)로 둔다. [keepScreen] 이면 말풍선은 그대로 두고
  /// (곧 [_load] 가 다시 그린다) 세션 · 저장 위치만 바꾼다. [loading] 은 곧 [_load] 가 이어
  /// 읽을 때 true. [openId] 는 곧 [_load] 가 읽을 대화 — 읽는 동안 [OpenConversation.id] 를
  /// 그 id 로 둬서 보관 정리가 지우지 않게 한다(턴이 없으면 [_load] 가 비운다).
  void _startFresh({
    required bool temporary,
    bool keepScreen = false,
    bool loading = false,
    String? openId,
  }) {
    _generation++;
    _thread = _Thread(temporary: temporary);
    unawaited(_sub?.cancel());
    _sub = null;
    _session.reset(temporary: temporary);
    // reset 뒤에 닫는다 — 어댑터가 끊으며 찍는 abort 가 이번 질문 기록에 들어가게.
    if (state.busy) _traceDone();
    _complete();
    emit(
      state.copyWith(
        bubbles: keepScreen ? state.bubbles : const [],
        busy: false,
        activeTool: null,
        temporary: temporary,
        loading: loading,
      ),
    );
    _setConversation(null);
    if (openId != null) _open.id = openId;
  }

  /// 저장된 [id] 의 턴으로 화면과 세션을 채운다. 그 사이 다른 대화로 바뀌었으면([thread]) 버린다.
  /// 턴이 없거나 읽지 못하면 빈 새 대화로 둔다. 끝나면(지금 대화일 때) loading 을 내린다.
  Future<void> _load(String id, _Thread thread) async {
    List<ChatTurnRecord> turns;
    try {
      turns = await _history.turns(id);
    } on Object {
      turns = const [];
    }
    if (isClosed || !identical(thread, _thread)) return;
    if (turns.isEmpty) {
      emit(state.copyWith(bubbles: const [], loading: false));
      _open.id = null;
      return;
    }
    final citedByTurn = await Future.wait([
      for (final turn in turns) _resolve(turn.citedEntryIds),
    ]);
    final bubbles = <ChatBubble>[];
    for (final (i, turn) in turns.indexed) {
      final cited = citedByTurn[i];
      bubbles
        ..add(
          ChatBubble(role: ChatRole.user, text: turn.question, seq: turn.seq),
        )
        ..add(
          ChatBubble(
            role: ChatRole.assistant,
            text: turn.answer,
            cited: cited,
            stopped: turn.stopped,
            seq: turn.seq,
          ),
        );
    }
    if (isClosed || !identical(thread, _thread)) return;
    thread.id = id;
    _session.resume([for (final t in turns) t.text], temporary: false);
    emit(state.copyWith(bubbles: bubbles, loading: false));
    _setConversation(id);
  }

  /// 마지막 턴(질문 · 답 말풍선)을 저장한다. 임시 대화 · 빈 답 · 실패는 저장하지 않는다.
  /// 저장이 던지면 조용히 넘어간다 — 말풍선은 남고 다음 턴이 다시 시도한다.
  Future<void> _saveLastTurn(
    List<String> citedEntryIds, {
    required bool stopped,
  }) {
    final thread = _thread;
    final target = _turnTarget;
    final bubbles = state.bubbles;
    if (thread.temporary || target == null || bubbles.length < 2) {
      return Future.value();
    }
    final userIndex = bubbles.length - 2;
    final user = bubbles[userIndex];
    final answer = bubbles.last;
    if (answer.failure != null || answer.text.trim().isEmpty) {
      return Future.value();
    }
    final draft = ChatTurnDraft(
      question: _turnQuestion,
      answer: answer.text,
      citedEntryIds: citedEntryIds,
      stopped: stopped,
      vendor: target.vendor,
      model: target.model,
    );
    final saved = _saveTail.then(
      (_) => _write(thread, draft, userIndex, user, answer),
    );
    _saveTail = saved;
    return saved;
  }

  Future<void> _write(
    _Thread thread,
    ChatTurnDraft draft,
    int userIndex,
    ChatBubble user,
    ChatBubble answer,
  ) async {
    final ChatTurnRef ref;
    try {
      ref = await _history.appendTurn(conversationId: thread.id, turn: draft);
    } on Object {
      return;
    }
    thread.id = ref.conversationId;
    // 그 사이 새 대화 · 다른 대화 · 임시 대화로 바뀌었으면 화면에 붙이지 않는다(행은 목록에 있다).
    if (isClosed || !identical(thread, _thread)) return;
    final bubbles = state.bubbles;
    final matches =
        userIndex + 1 < bubbles.length &&
        _same(bubbles[userIndex], user) &&
        _same(bubbles[userIndex + 1], answer);
    if (matches) {
      emit(
        state.copyWith(
          bubbles: [
            for (final (i, b) in bubbles.indexed)
              i == userIndex || i == userIndex + 1
                  ? b.copyWith(seq: ref.seq)
                  : b,
          ],
        ),
      );
    }
    _setConversation(ref.conversationId);
  }

  /// 열린 대화를 바꾼다 — 상태 · [OpenConversation] · 지워짐 감시를 함께.
  void _setConversation(String? id) {
    if (isClosed) return;
    if (state.conversationId != id) emit(state.copyWith(conversationId: id));
    if (_open.id == id && (id == null || _existsSub != null)) return;
    _open.id = id;
    unawaited(_existsSub?.cancel());
    _existsSub = null;
    if (id == null) return;
    _existsSub = _history.watchExists(id).listen((exists) {
      if (!exists && !isClosed && state.conversationId == id) {
        newConversation();
      }
    }, onError: (Object _) {});
  }

  /// 남은 말풍선에서 세션에 넘길 턴. 실패한 쌍 · 답 없는 질문은 뺀다.
  List<ChatTurnText> _turnsOf(List<ChatBubble> bubbles) => [
    for (var i = 0; i + 1 < bubbles.length; i++)
      if (bubbles[i].role == ChatRole.user &&
          bubbles[i + 1].role == ChatRole.assistant &&
          bubbles[i + 1].failure == null)
        ChatTurnText(
          question: bubbles[i].text,
          answer: bubbles[i + 1].text,
          stopped: bubbles[i + 1].stopped,
        ),
  ];

  ChatBubble? _bubbleAt(int index) =>
      index >= 0 && index < state.bubbles.length ? state.bubbles[index] : null;

  /// [bubble] 이 아직 [near] 에 있으면 그 index(저장이 seq 를 붙였을 수 있다). 아니면 null.
  int? _indexOf(ChatBubble bubble, {required int near}) {
    final at = _bubbleAt(near);
    return at != null && _same(at, bubble) ? near : null;
  }

  /// 저장 · 인용 붙이기가 바꾸는 seq · cited 를 빼고 같은 말풍선인가.
  static bool _same(ChatBubble a, ChatBubble b) =>
      identical(a, b) ||
      a.copyWith(seq: null, cited: const []) ==
          b.copyWith(seq: null, cited: const []);

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
    _generation++;
    unawaited(_existsSub?.cancel());
    _existsSub = null;
    _open.id = null;
    // 기다리지 않는다 — 응답을 기다리는 중인 세션 스트림은 취소가 늦게 끝날 수 있다.
    unawaited(_sub?.cancel());
    // 세션은 싱글턴이다. 답하는 중에 닫혀도 다음 cubit 이 ask 할 수 있게 비운다.
    _session.reset();
    // reset 뒤에 닫는다 — 어댑터가 끊으며 찍는 abort 가 이번 질문 기록에 들어가게.
    if (state.busy) _traceDone();
    _complete();
    return super.close();
  }
}
