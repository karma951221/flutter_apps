import 'dart:async';

import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

import '../chat_connection.dart';
import '../chat_model.dart';
import '../chat_settings.dart';
import '../chat_trace.dart';
import '../chat_usage_log.dart';
import '../chat_vendor.dart';
import '../entity/conversation.dart';
import '../tool/life_tools.dart';
import '../tool/tool_result.dart';
import '../tool/tool_summary.dart';
import '../tool/wiki_tools.dart';
import '../wiki/wiki_context_policy.dart';
import 'chat_model_choice.dart';

part 'chat_session.freezed.dart';

enum ChatFailure {
  noKey,

  /// 연결은 됐지만 모델 목록이 없다(받지 못함) — 보낼 모델이 없어 요청하지 않았다.
  noModels,
  invalidKey,
  quotaExceeded,
  modelUnavailable,

  /// 쓰던 모델이 없어져 목록을 다시 받아 다른 모델로 바꿨다. 다시 물으면 된다.
  modelReplaced,
  rateLimited,
  overloaded,
  network,
  refused,
  tooManySteps,
  unknown,
}

/// 모델 오류 → 화면 실패 종류. 물어보기와 위키 정리가 같이 쓴다.
/// 이미지 거절은 세션이 사진 없이 한 번 다시 보낸다. 또 나면(또는 정리 요청이면) unknown.
ChatFailure chatFailureOf(ChatModelErrorKind kind) => switch (kind) {
  ChatModelErrorKind.invalidKey => ChatFailure.invalidKey,
  ChatModelErrorKind.rateLimited => ChatFailure.rateLimited,
  ChatModelErrorKind.overloaded => ChatFailure.overloaded,
  ChatModelErrorKind.network => ChatFailure.network,
  ChatModelErrorKind.quotaExceeded => ChatFailure.quotaExceeded,
  ChatModelErrorKind.modelUnavailable => ChatFailure.modelUnavailable,
  ChatModelErrorKind.server ||
  ChatModelErrorKind.imagesUnsupported => ChatFailure.unknown,
};

/// 진행 줄의 단계. 도구 단계는 toolStarted 로 알린다.
enum ChatPhase { sending, thinking, writing }

@freezed
sealed class ChatEvent with _$ChatEvent {
  const ChatEvent._();

  const factory ChatEvent.phase(ChatPhase phase) = ChatPhaseChanged;

  /// 모델의 진행 노트(누적 글 — 바꿔 끼운다). 0번이 정상.
  const factory ChatEvent.progress(String note) = ChatProgressNote;

  /// 도구 블록이 열림([input] null) → 입력 완성([input] 있음). 같은 [callId] 로 두 번 올 수 있다.
  const factory ChatEvent.toolStarted({
    required String callId,
    required String name,
    ToolInputSummary? input,
  }) = ChatToolStarted;
  const factory ChatEvent.toolFinished({
    required String callId,
    required String name,
    required ToolSummary summary,
  }) = ChatToolFinished;

  /// 2라운드부터. 1라운드는 phase(sending) 가 시작이다.
  const factory ChatEvent.roundStarted(int round) = ChatRoundStarted;
  const factory ChatEvent.text(String delta) = ChatText;
  const factory ChatEvent.finished({required List<String> citedEntryIds}) =
      ChatFinished;
  const factory ChatEvent.failed(ChatFailure failure) = ChatFailed;

  /// 진행 노트 · 답 글은 길이만 — 모델이 쓴 글을 로그에 남기지 않는다.
  /// toolStarted 는 [ToolInputSummary.toString] 이라 검색어가 없다.
  @override
  String toString() => switch (this) {
    ChatPhaseChanged(:final phase) => 'ChatEvent.phase($phase)',
    ChatProgressNote(:final note) => 'ChatEvent.progress(${note.length} chars)',
    ChatToolStarted(:final callId, :final name, :final input) =>
      'ChatEvent.toolStarted(callId: $callId, name: $name, input: $input)',
    ChatToolFinished(:final callId, :final name, :final summary) =>
      'ChatEvent.toolFinished(callId: $callId, name: $name, summary: $summary)',
    ChatRoundStarted(:final round) => 'ChatEvent.roundStarted($round)',
    ChatText(:final delta) => 'ChatEvent.text(${delta.length} chars)',
    ChatFinished(:final citedEntryIds) =>
      'ChatEvent.finished(citedEntryIds: $citedEntryIds)',
    ChatFailed(:final failure) => 'ChatEvent.failed($failure)',
  };
}

/// [ChatSession.stop] 의 결과. toString 에 받은 글을 남기지 않는다.
@Freezed(toStringOverride: false)
sealed class ChatStopResult with _$ChatStopResult {
  /// 진행 중인 질문이 없었다(이미 끝났거나 리셋됨). 아무것도 바꾸지 않았다.
  const factory ChatStopResult.idle() = ChatStopIdle;

  /// 받은 글을 남겼다. [text] 는 화면에 흘린 글과 같은 문자열, [citedEntryIds] 는 그때까지 도구가 찾은 일기 id.
  const factory ChatStopResult.kept({
    required String text,
    required List<String> citedEntryIds,
  }) = ChatStopKept;

  /// 받은 글이 없어 질문까지 되돌렸다.
  const factory ChatStopResult.dropped() = ChatStopDropped;
}

/// 질문에 쓸 벤더 · 모델. [ChatSession.target] 이 설정 · 모델 목록에서 읽는다.
typedef ChatTarget = ({ChatVendor vendor, String model});

/// 한 대화. 질문마다 Claude 를 부르고, 도구를 요청하면 실행해 결과를 돌려준다.
///
/// 대화 기록은 덧붙이기만 한다(assistant 턴의 vendorState 도 그대로).
/// 질문이 실패하거나 중간에 구독이 끊기면 그 질문에서 덧붙인 메시지를 되돌린다.
/// 멈춤은 꼬리만 글로 바꾼다.
/// 메모리의 지금 대화는 고치지 않는다 · 저장 · 복원 · 벤더 교체는 글만.
/// 예외는 벤더가 바뀔 때 — 다음 질문 전에 문맥을 글로 접는다([target]). 같은 벤더 안에서
/// 모델만 바뀌면 그대로 보내고, 어댑터가 다른 모델의 턴을 다시 만든다.
/// 사진 못 보는 모델에는 요청에서만 사진을 뺀다(메모리 문맥은 그대로).
/// 질문마다 WikiContextPolicy 로 위키 색인 · read_wiki 를 붙인다 — 임시 대화는 붙이지 않는다.
@lazySingleton
class ChatSession {
  ChatSession(
    this._registry,
    this._tools,
    this._settings,
    this._choice,
    this._clock,
    this._usage,
    this._ids,
    this._trace,
    this._wiki,
    this._wikiTools,
  );

  final ChatModelRegistry _registry;
  final LifeTools _tools;
  final ChatSettings _settings;
  final ChatModelChoice _choice;
  final Clock _clock;
  final ChatUsageLog _usage;
  final IdGenerator _ids;
  final ChatTrace _trace;
  final WikiContextPolicy _wiki;
  final WikiTools _wikiTools;

  static const maxRounds = 8;

  /// 한 대화에 보내는 사진 수 한도. 메모리의 지금 대화는 고치지 않으므로(thinking
  /// 서명이 깨진다) 보낸 사진은 매 요청에 다시 실린다 — 대신 한도에서 막는다.
  static const maxImagesPerConversation = 12;

  /// 멈춘 답 끝에 붙여 다음 문맥에 넣는 표시. 기록 기획의 resume 도 같은 상수를 쓴다.
  static const stoppedNote = '(사용자가 여기서 멈춤)';

  /// 지난 대화를 이어갈 때 문맥에 싣는 최근 턴 수.
  static const resumeTurns = 20;

  static const _photoLimitJson =
      '{"error":"photo_limit_reached",'
      '"hint":"대화를 다시 열거나 새 대화를 시작하면 다시 사진을 볼 수 있어요"}';

  final _messages = <ChatMessage>[];
  bool _busy = false;
  bool _temporary = false;

  /// 메모리 문맥(vendorState 포함)을 만든 벤더 · 모델. 라운드가 끝날 때(completed)
  /// 그 요청의 target 으로 둔다. 글만의 문맥([reset] · [resume] · 접은 뒤)은 null —
  /// 어디로든 보낼 수 있다. 벤더가 다를 때만 접는다(모델만 다르면 어댑터 몫).
  ChatTarget? _contextTarget;

  /// 다음 질문의 벤더 · 모델. 미연결이거나 모델 목록이 없으면 null.
  /// = (연결 벤더, 고른 모델 또는 추천).
  ChatTarget? get target {
    final vendor = _settings.connectedVendor;
    final model = _choice.currentModel;
    if (vendor == null || model == null) return null;
    return (vendor: vendor, model: model);
  }

  /// 임시 대화인가. 사용량 기록의 temporary 로 간다.
  bool get temporary => _temporary;

  /// 이 대화에서 보낸 사진 수. 되돌린 질문의 사진은 세지 않는다.
  int _imagesSent = 0;

  /// [reset] 마다 올린다. 진행 중인 질문은 자기 세대가 바뀌면 조용히 멈춘다.
  int _generation = 0;

  /// 진행 중인 라운드의 모델 구독과 그 이벤트를 [_run] 에 넘기는 relay.
  /// `await for` 로 모델 스트림을 바로 돌면 세션 구독 취소가 다음 이벤트까지
  /// 모델에 닿지 않는다 — 그래서 구독을 직접 쥐고 [reset] 에서 끊는다.
  StreamSubscription<ModelEvent>? _roundSub;
  StreamController<ModelEvent>? _roundRelay;

  /// 진행 중인 질문의 시작점 · 질문 · 흘린 글 · 찾은 일기 id. [stop] 이 쓴다.
  /// [ask] 에서 동기로 채운다 — [_run] 본문은 구독한 뒤에야 돈다.
  int _turnStart = 0;
  int _turnImagesAtStart = 0;
  String _turnQuestion = '';
  final _turnText = StringBuffer();
  final _turnCited = <String>{};

  /// 이번 질문이 finished 를 냈다. 그 뒤 생성기가 마저 끝나기 전([_busy] 가 아직
  /// true)에 [stop] 이 와도 끝난 답을 지우지 않게 한다.
  bool _turnDone = false;

  /// 한 번에 하나. 진행 중에 부르면 [StateError].
  Stream<ChatEvent> ask(String question) {
    if (_busy) throw StateError('ChatSession.ask is already running');
    _busy = true;
    final requestTarget = target;
    final context = _contextTarget;
    if (context != null &&
        requestTarget != null &&
        context.vendor != requestTarget.vendor) {
      _foldToText();
    }
    _turnStart = _messages.length;
    _turnImagesAtStart = _imagesSent;
    _turnQuestion = question;
    _turnText.clear();
    _turnCited.clear();
    _turnDone = false;
    return _run(question, _generation, requestTarget);
  }

  /// 진행 중인 질문을 멈춘다. [reset] 처럼 세대를 올리고 끊지만 대화는 비우지 않는다.
  /// 이번 질문 몫을 지우고, 받은 글이 있으면 질문과 그 글(+ [stoppedNote])만 남긴다.
  /// 이벤트는 내지 않는다 — 결과는 반환값으로.
  ///
  /// 호출 순서: [stop] 을 먼저 부르는 것이 기본이다 — 루프가 stale() 을 보고 끝나므로
  /// 그 뒤의 구독 취소는 바로 끝난다. 구독을 먼저 끊을 때는 취소를 기다리지 말고
  /// 곧바로 [stop] 을 부른다. `await sub.cancel()` 뒤에 부르면 안 된다 — 취소가 모델의
  /// 다음 이벤트까지 걸릴 수 있고, 그 사이 질문이 스스로 되돌려져 [stop] 은 idle 을
  /// 돌려주며 받은 글을 잃는다.
  ChatStopResult stop() {
    if (!_busy || _turnDone) return const ChatStopResult.idle();
    _generation++;
    _cancelRound();
    _busy = false;
    if (_turnStart <= _messages.length) {
      _messages.removeRange(_turnStart, _messages.length);
    }
    _imagesSent = _turnImagesAtStart;
    final text = _turnText.toString();
    if (text.trim().isEmpty) return const ChatStopResult.dropped();
    _messages
      ..add(ChatMessage.user(_turnQuestion))
      ..add(
        ChatMessage.assistant(
          parts: [AssistantPart.text('$text\n$stoppedNote')],
        ),
      );
    return ChatStopResult.kept(text: text, citedEntryIds: [..._turnCited]);
  }

  /// 대화 비우기. 진행 중이어도 부를 수 있다 — 그 질문은 더 덧붙이지도,
  /// 이벤트를 내지도 않고 끝나며, 바로 다음 [ask] 를 받을 수 있다.
  /// [temporary] 는 새 대화가 임시 대화인지 — 사용량 기록에 남는다.
  void reset({bool temporary = false}) {
    _generation++;
    _messages.clear();
    _imagesSent = 0;
    _busy = false;
    _temporary = temporary;
    _contextTarget = null;
    // 세대를 올린 뒤에 끊는다 — 닫힌 relay 로 루프가 끝나면 stale() 로 조용히 나간다.
    _cancelRound();
  }

  /// 지난 대화를 이어간다. [reset] 처럼 세대를 올리고 진행 중인 라운드를 끊은 뒤,
  /// [turns] 의 마지막 [resumeTurns] 개로 문맥을 글로만 채운다. 멈춘 턴은 답 뒤에
  /// [stoppedNote] 줄을 붙이고, 답이 빈 턴은 싣지 않는다. 사진 수는 0부터 다시 센다.
  void resume(List<ChatTurnText> turns, {required bool temporary}) {
    reset(temporary: temporary);
    final recent = turns.length > resumeTurns
        ? turns.sublist(turns.length - resumeTurns)
        : turns;
    for (final turn in recent) {
      if (turn.answer.trim().isEmpty) continue;
      final answer = turn.stopped
          ? '${turn.answer}\n$stoppedNote'
          : turn.answer;
      _messages
        ..add(ChatMessage.user(turn.question))
        ..add(ChatMessage.assistant(parts: [AssistantPart.text(answer)]));
    }
  }

  /// 메모리 문맥을 질문 단위의 글로 접는다 — 다른 벤더는 vendorState ·
  /// 도구 호출 · 도구 결과를 읽지 못한다. 질문마다 assistant 메시지(라운드)별 글을
  /// 빈 줄로 이어 하나로 두고, 글이 비면 그 질문째 버린다. 접은 글은 모델에만 가고
  /// 화면에는 나오지 않는다. 사진도 함께 빠지므로 사진 수는 0.
  void _foldToText() {
    final folded = <ChatMessage>[];
    String? question;
    final rounds = <String>[];
    void flush() {
      final q = question;
      if (q != null && rounds.isNotEmpty) {
        folded
          ..add(ChatMessage.user(q))
          ..add(
            ChatMessage.assistant(
              parts: [AssistantPart.text(rounds.join('\n\n'))],
            ),
          );
      }
      question = null;
      rounds.clear();
    }

    for (final message in _messages) {
      switch (message) {
        case UserMessage(:final text):
          flush();
          question = text;
        case AssistantMessage(:final parts):
          final text = parts.whereType<TextPart>().map((p) => p.text).join();
          if (text.trim().isNotEmpty) rounds.add(text);
        case ToolResultsMessage():
          break;
      }
    }
    flush();
    _messages
      ..clear()
      ..addAll(folded);
    _imagesSent = 0;
    _contextTarget = null;
  }

  /// 진행 중인 라운드의 모델 구독을 끊고 relay 를 닫아 _run 의 await for 를 끝낸다.
  void _cancelRound() {
    final sub = _roundSub;
    final relay = _roundRelay;
    _roundSub = null;
    _roundRelay = null;
    // 기다리지 않는다 — 모델 쪽 정리가 reset 을 묶지 않게.
    sub?.cancel().ignore();
    if (relay != null && !relay.isClosed) unawaited(relay.close());
  }

  Stream<ChatEvent> _run(
    String question,
    int generation,
    ChatTarget? target,
  ) async* {
    bool stale() => generation != _generation;
    final start = _messages.length;
    final imagesAtStart = _imagesSent;
    var completed = false;
    // 이 질문이 쓴 키. 키 상태 기록 직전 저장된 키와 비교만 한다(어디에도 싣지 않음).
    String? requestKey;
    // 요청을 보낸 벤더 · 모델. 오류 처리(modelUnavailable)가 쓴다.
    ChatTarget? requestTarget;
    // 지금 진행 단계. thinking 이 연달아 와도 한 번만 알린다.
    ChatPhase? phase = ChatPhase.sending;
    try {
      // try 안에서 — 첫 이벤트에서 구독을 끊어도 finally 가 돌아 _busy 가 풀린다.
      yield const ChatEvent.phase(ChatPhase.sending);
      final apiKey = requestKey = await _settings.apiKey();
      // 표시보다 stale() 이 먼저 — 지난 질문의 늦은 표시가 다음 질문 기록에 섞이지 않게.
      if (stale()) return;
      if (_trace.enabled) _trace.mark(ChatTraceMark.key);
      if (apiKey == null) {
        yield const ChatEvent.failed(ChatFailure.noKey);
        return;
      }
      if (target == null) {
        yield const ChatEvent.failed(ChatFailure.noModels);
        return;
      }
      requestTarget = target;
      // 질문마다 한 번 — 이 질문의 라운드 동안 system · 도구가 고정된다.
      final wiki = _temporary ? WikiContext.none : await _safeWiki(question);
      if (stale()) return;
      final model = _registry.of(target.vendor);
      // 질문 동안 고정한다 — 그 사이 모델 · 빠른 출력을 바꾸면 다음 질문부터.
      final fastMode = _choice.fastModeOn;
      // 이미지 거절(imagesUnsupported)을 받으면 이 질문의 남은 요청은 사진 없이.
      var images = _choice.supportsImages;
      var retriedWithoutImages = false;
      final system = _systemPrompt(
        progressNotes: model.progressNotes,
        wikiSection: wiki.systemSection,
      );
      // 위키 도구가 실린 질문에서만 read_wiki 를 WikiTools 로 보낸다.
      final wikiOn = wiki.tools.isNotEmpty;
      final questionKey = _ids.newId();
      _messages.add(ChatMessage.user(question));

      for (var round = 1; round <= maxRounds; round++) {
        ModelCompleted? done;
        if (round >= 2) {
          phase = null;
          yield ChatEvent.roundStarted(round);
        }
        // 이 라운드에 아직 글이 없다 — 첫 조각 앞에 경계 줄바꿈을 넣을지 본다.
        var firstText = true;
        // 모델이 toolCallReady(입력 완성)로 알린 도구 호출 id. 알리지 않은 호출은
        // 실행 전에 세션이 입력과 함께 toolStarted 를 낸다(그런 이벤트가 없는 어댑터 대비).
        final announced = <String>{};
        // 이미지 거절이면 같은 라운드를 사진 없이 한 번만 다시 보낸다.
        while (true) {
          final request = ModelRequest(
            apiKey: apiKey,
            model: target.model,
            fastMode: fastMode,
            system: system,
            messages: _requestMessages(images: images),
            tools: _toolsFor(images: images, wiki: wiki),
          );
          if (_trace.enabled) _trace.mark(ChatTraceMark.round, {'n': round});
          StreamSubscription<ModelEvent>? roundSub;
          // 이 질문의 구독자가 떠나 await for 가 끝나도 모델 구독을 끊는다.
          final relay = StreamController<ModelEvent>(
            sync: true,
            onCancel: () => roundSub?.cancel().ignore(),
          );
          _roundRelay = relay;
          _roundSub = roundSub = model
              .stream(request)
              .listen(relay.add, onError: relay.addError, onDone: relay.close);
          try {
            await for (final event in relay.stream) {
              if (stale()) return;
              switch (event) {
                case ModelTextDelta(:final text):
                  if (phase != ChatPhase.writing) {
                    phase = ChatPhase.writing;
                    yield const ChatEvent.phase(ChatPhase.writing);
                  }
                  // 라운드 경계: 이 질문에 이미 글이 있으면 새 라운드 첫 조각 앞에
                  // 줄바꿈 하나 — 흘린 글과 _turnText 가 같은 문자열이 되게 여기서 넣는다.
                  // 빈 조각은 첫 조각으로 치지 않는다 — 줄바꿈만 흘리지 않게.
                  final delta =
                      firstText && text.isNotEmpty && _turnText.isNotEmpty
                      ? '\n$text'
                      : text;
                  if (text.isNotEmpty) firstText = false;
                  _turnText.write(delta);
                  yield ChatEvent.text(delta);
                case ModelCompleted():
                  done = event;
                  // 받는 즉시 남긴다 — 청구된 라운드는 HTTP 가 닫히기 전에 멈추거나
                  // 비워도, 뒤 라운드가 실패해도 기록에 남아야 한다.
                  _recordUsage(
                    questionKey,
                    round,
                    target,
                    request,
                    event.usage,
                    wiki,
                    // 위키 도구가 없던 질문의 read_wiki 는 실행하지 않으니 세지 않는다.
                    wikiOn ? _readWikiCalls(event.message) : 0,
                  );
                case ModelThinking():
                  if (phase != ChatPhase.thinking) {
                    phase = ChatPhase.thinking;
                    yield const ChatEvent.phase(ChatPhase.thinking);
                  }
                case ModelProgress(:final text):
                  yield ChatEvent.progress(text);
                case ModelToolCallStarted(:final id, :final name):
                  // 입력 없는 알림 — ready 가 오지 않으면 실행 전에 세션이 입력과 함께 다시 낸다.
                  phase = null;
                  yield ChatEvent.toolStarted(callId: id, name: name);
                case ModelToolCallReady(:final id, :final name, :final input):
                  phase = null;
                  announced.add(id);
                  yield ChatEvent.toolStarted(
                    callId: id,
                    name: name,
                    input: _tools.inputSummary(name, input),
                  );
              }
            }
          } on ChatModelException catch (e) {
            if (e.kind != ChatModelErrorKind.imagesUnsupported ||
                !images ||
                retriedWithoutImages ||
                stale()) {
              rethrow;
            }
            retriedWithoutImages = true;
            images = false;
            // 표시 저장이 실패해도 이 질문은 사진 없이 다시 보낸다.
            try {
              await _choice.markNoImages(target.model);
            } on Object catch (_) {}
            if (stale()) return;
            continue;
          }
          if (identical(_roundRelay, relay)) {
            _roundRelay = null;
            _roundSub = null;
          }
          break;
        }
        if (stale()) return;
        if (done == null) {
          throw const ChatModelException(ChatModelErrorKind.network);
        }
        _messages.add(done.message);

        switch (done.stop) {
          case StopKind.toolUse:
            // 도구는 모두 바로 시작하고(병렬), 끝나는 대로 toolFinished 를 낸다.
            // 기록 · 사진 한도 · 인용 정리는 호출 순서로 한 번에(R7).
            final calls = [
              for (final p in done.message.parts)
                if (p case ToolCallPart c) c,
            ];
            for (final c in calls) {
              if (announced.contains(c.id)) continue;
              yield ChatEvent.toolStarted(
                callId: c.id,
                name: c.name,
                input: _tools.inputSummary(c.name, c.input),
              );
            }
            if (stale()) return;
            if (_trace.enabled) {
              for (final c in calls) {
                _trace.mark(ChatTraceMark.toolStart, {'tool': c.name});
              }
            }
            final futures = [
              for (final c in calls)
                if (wikiOn && c.name == WikiTools.readWikiName)
                  _wikiTools.readWiki(c.input)
                else
                  _tools.run(c.name, c.input),
            ];
            final results = List<ToolResult?>.filled(calls.length, null);
            await for (final (i, result) in _inCompletionOrder(futures)) {
              if (stale()) return;
              results[i] = result;
              final call = calls[i];
              if (_trace.enabled) {
                // 개수만 — 결과 본문 · 입력값은 찍지 않는다.
                _trace.mark(ChatTraceMark.toolEnd, {
                  'tool': call.name,
                  'n': result.entryIds.length + result.images.length,
                });
              }
              yield ChatEvent.toolFinished(
                callId: call.id,
                name: call.name,
                summary:
                    result.summary ??
                    ToolSummary(kind: chatToolKindOf(call.name), count: 0),
              );
            }
            if (stale()) return;
            final parts = <ToolResultPart>[];
            for (var i = 0; i < calls.length; i++) {
              final result = results[i]!;
              _turnCited.addAll(result.entryIds);
              final capped = _capped(result, images: images);
              parts.add(
                ToolResultPart(
                  callId: calls[i].id,
                  json: capped.json,
                  isError: capped.isError,
                  images: capped.images,
                ),
              );
            }
            _messages.add(ChatMessage.toolResults(parts));
          case StopKind.refusal:
            yield const ChatEvent.failed(ChatFailure.refused);
            return;
          case StopKind.endTurn || StopKind.maxTokens || StopKind.other:
            completed = true;
            _turnDone = true;
            _contextTarget = target;
            _recordKeyStatus(ChatKeyStatus.valid, apiKey);
            yield ChatEvent.finished(citedEntryIds: List.of(_turnCited));
            return;
        }
      }
      yield const ChatEvent.failed(ChatFailure.tooManySteps);
    } on ChatModelException catch (e) {
      if (!stale()) {
        var failure = chatFailureOf(e.kind);
        if (failure == ChatFailure.invalidKey) {
          _recordKeyStatus(ChatKeyStatus.invalid, requestKey);
        }
        final failed = requestTarget;
        if (failure == ChatFailure.modelUnavailable && failed != null) {
          // 목록을 다시 받아 지금 모델이 바뀌었으면 다시 물으면 된다(§6.3 끝).
          final replaced = await _recoverFromUnavailable(failed.model);
          if (stale()) return;
          if (replaced) failure = ChatFailure.modelReplaced;
        }
        yield ChatEvent.failed(failure);
      }
    } catch (_) {
      if (!stale()) yield const ChatEvent.failed(ChatFailure.unknown);
    } finally {
      // 세대가 바뀌었으면 기록과 _busy 는 이미 새 세대의 것이다.
      if (!stale()) {
        _busy = false;
        if (!completed && start <= _messages.length) {
          _messages.removeRange(start, _messages.length);
          _imagesSent = imagesAtStart;
        }
      }
    }
  }

  /// [futures] 의 결과를 끝나는 순서대로 (자리, 결과) 로 낸다. 하나가 던지면 그 자리는
  /// tool_failed 오류 결과 — [LifeTools.run] 이 이미 잡지만 방어로.
  static Stream<(int, ToolResult)> _inCompletionOrder(
    List<Future<ToolResult>> futures,
  ) {
    final controller = StreamController<(int, ToolResult)>();
    if (futures.isEmpty) {
      unawaited(controller.close());
      return controller.stream;
    }
    var left = futures.length;
    for (final (i, future) in futures.indexed) {
      future
          .then(
            (r) => r,
            onError: (Object _) => const ToolResult(
              json: '{"error":"tool_failed"}',
              isError: true,
            ),
          )
          .then((r) {
            if (controller.isClosed) return;
            controller.add((i, r));
            if (--left == 0) unawaited(controller.close());
          });
    }
    return controller.stream;
  }

  /// 라운드 하나의 사용량을 넘긴다. 기다리지 않고, 실패해도 답에 영향을 주지 않는다.
  void _recordUsage(
    String questionKey,
    int round,
    ChatTarget requestTarget,
    ModelRequest request,
    TokenUsage? usage,
    WikiContext wiki,
    int readWikiCalls,
  ) {
    if (usage == null) return;
    final record = ChatUsageRecord(
      at: _clock.now(),
      questionKey: questionKey,
      vendor: requestTarget.vendor,
      model: requestTarget.model,
      fastMode: request.fastMode,
      purpose: ChatUsagePurpose.chat,
      round: round,
      temporary: _temporary,
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
      cacheReadTokens: usage.cacheReadTokens,
      cacheWriteTokens: usage.cacheWriteTokens,
      reasoningTokens: usage.reasoningTokens,
      wikiIndexNotes: wiki.indexNotes,
      wikiIndexChars: wiki.indexChars,
      readWikiCalls: readWikiCalls,
    );
    unawaited(
      Future.sync(() => _usage.record(record)).catchError((Object _) {}),
    );
  }

  /// LifeTools 정의 뒤에 위키 도구. 위키가 없으면 LifeTools 정의 그대로.
  List<ToolSpec> _toolsFor({required bool images, required WikiContext wiki}) {
    final life = _tools.definitionsFor(images: images);
    return wiki.tools.isEmpty ? life : [...life, ...wiki.tools];
  }

  static int _readWikiCalls(AssistantMessage message) => message.parts
      .where((p) => p is ToolCallPart && p.name == WikiTools.readWikiName)
      .length;

  /// 정책이 던지면 위키 없이 — 질문은 계속한다.
  Future<WikiContext> _safeWiki(String question) async {
    try {
      return await _wiki.build(question: question);
    } catch (_) {
      return WikiContext.none;
    }
  }

  /// 키 상태를 남긴다(§7.3). 기다리지 않고, 실패해도 답에 영향을 주지 않는다.
  /// stale 한 질문은 부르지 않는다(부르는 쪽이 확인). 질문 동안 키를 바꾸거나
  /// 끊었으면([usedKey] 와 지금 저장된 키가 다르면) setKeyStatus 가 남기지 않는다.
  void _recordKeyStatus(ChatKeyStatus status, String? usedKey) {
    if (usedKey == null) return;
    unawaited(
      Future.sync(
        () => _settings.setKeyStatus(status, forKey: usedKey),
      ).catchError((Object _) {}),
    );
  }

  /// 던지지 않는다 — 갱신이 실패하면 false(modelUnavailable 그대로).
  Future<bool> _recoverFromUnavailable(String model) async {
    try {
      return await _choice.recoverFromUnavailable(model);
    } catch (_) {
      return false;
    }
  }

  /// 요청에 실을 문맥. [images] 가 false 면 도구 결과의 사진을 비운 사본 —
  /// 메모리 문맥([_messages])은 그대로라 사진 되는 모델로 돌아오면 다시 실린다.
  List<ChatMessage> _requestMessages({required bool images}) {
    if (images) return List.unmodifiable(_messages);
    return List.unmodifiable([
      for (final message in _messages)
        switch (message) {
          ToolResultsMessage(:final results)
              when results.any((r) => r.images.isNotEmpty) =>
            ChatMessage.toolResults([
              for (final r in results)
                r.images.isEmpty ? r : r.copyWith(images: const []),
            ]),
          _ => message,
        },
    ]);
  }

  /// 사진이 한도를 넘기면 사진 없이 오류 결과로 바꾼다. [images] 가 false(사진 못 보는
  /// 모델)면 사진을 싣지도, 세지도 않는다 — 실제로 보낸 사진만 센다.
  ToolResult _capped(ToolResult result, {required bool images}) {
    final count = result.images.length;
    if (count == 0) return result;
    if (!images) return result.copyWith(images: const []);
    if (_imagesSent + count > maxImagesPerConversation) {
      return const ToolResult(json: _photoLimitJson, isError: true);
    }
    _imagesSent += count;
    return result;
  }

  /// 도구 전 한 줄 안내. [ChatModel.progressNotes] 인 모델에만 넣는다(V5 결과로 빼기 쉽게 상수).
  static const _noteHint = '도구를 쓰기 전에 무엇을 볼지 한 줄로 말해.';

  /// 순서: 규약 → 위키 절(있을 때) → 도구 전 안내 → 날짜 줄. 날짜 줄은 맨 끝 —
  /// 그 앞까지가 날마다(위키가 그대로면) 같은 캐시 접두부다.
  String _systemPrompt({required bool progressNotes, String? wikiSection}) {
    final now = _clock.now();
    final today = DateFormat('yyyy-MM-dd (E)', 'ko').format(now);
    final grounds = wikiSection == null ? '찾은 기록에' : '찾은 기록과 위키에';
    return '너는 사용자의 개인 기록 앱 Life Tool 안의 도우미다.\n'
        '사용자의 일기 · 걸음 수 · 알람 기상 기록을 도구로 찾아보고, $grounds 근거해서만 답한다.\n'
        '기록에서 찾지 못한 것은 추측하지 말고 "기록에서 찾지 못했어요"라고 말한다.\n'
        '날짜는 사용자의 말("지난주", "어제")을 오늘 기준으로 바꿔 도구에 넘긴다.\n'
        '사진 보기 도구가 없으면 사진은 볼 수 없다고 짧게 답한다.\n'
        '한국어로, 마크다운 없이 짧은 평문으로 답한다.\n'
        '${wikiSection == null ? '' : '\n$wikiSection\n\n'}'
        '${progressNotes ? '$_noteHint\n' : ''}'
        '오늘은 $today, 시간대는 ${now.timeZoneName} 이다.';
  }
}
