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
import '../tool/life_tools.dart';
import '../tool/tool_result.dart';

part 'chat_session.freezed.dart';

enum ChatFailure {
  noKey,
  invalidKey,
  quotaExceeded,
  modelUnavailable,
  rateLimited,
  overloaded,
  network,
  refused,
  tooManySteps,
  unknown,
}

@freezed
sealed class ChatEvent with _$ChatEvent {
  const factory ChatEvent.text(String delta) = ChatText;
  const factory ChatEvent.toolStarted(String toolName) = ChatToolStarted;
  const factory ChatEvent.finished({required List<String> citedEntryIds}) =
      ChatFinished;
  const factory ChatEvent.failed(ChatFailure failure) = ChatFailed;
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

/// 한 대화. 질문마다 Claude 를 부르고, 도구를 요청하면 실행해 결과를 돌려준다.
///
/// 대화 기록은 덧붙이기만 한다(assistant 턴의 vendorState 도 그대로).
/// 질문이 실패하거나 중간에 구독이 끊기면 그 질문에서 덧붙인 메시지를 되돌린다.
/// 멈춤은 꼬리만 글로 바꾼다 — 앞선 기록은 고치지 않는다.
@lazySingleton
class ChatSession {
  ChatSession(
    this._model,
    this._tools,
    this._settings,
    this._clock,
    this._usage,
    this._ids,
    this._trace,
  );

  final ChatModel _model;
  final LifeTools _tools;
  final ChatSettings _settings;
  final Clock _clock;
  final ChatUsageLog _usage;
  final IdGenerator _ids;
  final ChatTrace _trace;

  static const maxRounds = 8;

  /// 키 기획 ① 동안 쓰는 모델 id. 요청마다 [ModelRequest.model] 로 넘긴다.
  /// 키 기획 ③ 이 모델 카탈로그로 바꾸며 지운다.
  static const interimModel = 'claude-opus-5-5';

  /// 한 대화에 보내는 사진 수 한도. 지난 메시지는 고치지 않으므로(thinking 서명이
  /// 깨진다) 보낸 사진은 매 요청에 다시 실린다 — 대신 한도에서 막는다.
  static const maxImagesPerConversation = 12;

  /// 멈춘 답 끝에 붙여 다음 문맥에 넣는 표시. 기록 기획의 resume 도 같은 상수를 쓴다.
  static const stoppedNote = '(사용자가 여기서 멈춤)';

  static const _photoLimitJson =
      '{"error":"photo_limit_reached","hint":"새 대화를 시작하면 다시 사진을 볼 수 있어요"}';

  final _messages = <ChatMessage>[];
  bool _busy = false;

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
    _turnStart = _messages.length;
    _turnImagesAtStart = _imagesSent;
    _turnQuestion = question;
    _turnText.clear();
    _turnCited.clear();
    _turnDone = false;
    return _run(question, _generation);
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
  void reset() {
    _generation++;
    _messages.clear();
    _imagesSent = 0;
    _busy = false;
    // 세대를 올린 뒤에 끊는다 — 닫힌 relay 로 루프가 끝나면 stale() 로 조용히 나간다.
    _cancelRound();
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

  Stream<ChatEvent> _run(String question, int generation) async* {
    bool stale() => generation != _generation;
    final start = _messages.length;
    final imagesAtStart = _imagesSent;
    var completed = false;
    try {
      final apiKey = await _settings.apiKey();
      // 표시보다 stale() 이 먼저 — 지난 질문의 늦은 표시가 다음 질문 기록에 섞이지 않게.
      if (stale()) return;
      if (_trace.enabled) _trace.mark(ChatTraceMark.key);
      if (apiKey == null) {
        yield const ChatEvent.failed(ChatFailure.noKey);
        return;
      }
      final system = _systemPrompt();
      final tools = _tools.definitions;
      final questionKey = _ids.newId();
      _messages.add(ChatMessage.user(question));

      for (var round = 1; round <= maxRounds; round++) {
        ModelCompleted? done;
        final request = ModelRequest(
          apiKey: apiKey,
          model: interimModel,
          system: system,
          messages: List.unmodifiable(_messages),
          tools: tools,
        );
        if (_trace.enabled) _trace.mark(ChatTraceMark.round, {'n': round});
        StreamSubscription<ModelEvent>? roundSub;
        // 이 질문의 구독자가 떠나 await for 가 끝나도 모델 구독을 끊는다.
        final relay = StreamController<ModelEvent>(
          sync: true,
          onCancel: () => roundSub?.cancel().ignore(),
        );
        _roundRelay = relay;
        _roundSub = roundSub = _model
            .stream(request)
            .listen(relay.add, onError: relay.addError, onDone: relay.close);
        await for (final event in relay.stream) {
          if (stale()) return;
          switch (event) {
            case ModelTextDelta(:final text):
              _turnText.write(text);
              yield ChatEvent.text(text);
            case ModelCompleted():
              done = event;
              // 받는 즉시 남긴다 — 청구된 라운드는 HTTP 가 닫히기 전에 멈추거나
              // 비워도, 뒤 라운드가 실패해도 기록에 남아야 한다.
              _recordUsage(questionKey, round, request, event.usage);
            case ModelThinking() ||
                ModelProgress() ||
                ModelToolCallStarted() ||
                ModelToolCallReady():
              break;
          }
        }
        if (identical(_roundRelay, relay)) {
          _roundRelay = null;
          _roundSub = null;
        }
        if (stale()) return;
        if (done == null) {
          throw const ChatModelException(ChatModelErrorKind.network);
        }
        _messages.add(done.message);

        switch (done.stop) {
          case StopKind.toolUse:
            final results = <ToolResultPart>[];
            for (final part in done.message.parts) {
              if (part is! ToolCallPart) continue;
              yield ChatEvent.toolStarted(part.name);
              if (_trace.enabled) {
                _trace.mark(ChatTraceMark.toolStart, {'tool': part.name});
              }
              final result = await _tools.run(part.name, part.input);
              if (stale()) return;
              if (_trace.enabled) {
                // 개수만 — 결과 본문 · 입력값은 찍지 않는다.
                _trace.mark(ChatTraceMark.toolEnd, {
                  'tool': part.name,
                  'n': result.entryIds.length + result.images.length,
                });
              }
              _turnCited.addAll(result.entryIds);
              final capped = _capped(result);
              results.add(
                ToolResultPart(
                  callId: part.id,
                  json: capped.json,
                  isError: capped.isError,
                  images: capped.images,
                ),
              );
            }
            _messages.add(ChatMessage.toolResults(results));
          case StopKind.refusal:
            yield const ChatEvent.failed(ChatFailure.refused);
            return;
          case StopKind.endTurn || StopKind.maxTokens || StopKind.other:
            completed = true;
            _turnDone = true;
            _recordKeyStatus(ChatKeyStatus.valid);
            yield ChatEvent.finished(citedEntryIds: List.of(_turnCited));
            return;
        }
      }
      yield const ChatEvent.failed(ChatFailure.tooManySteps);
    } on ChatModelException catch (e) {
      if (!stale()) {
        final failure = _failureOf(e.kind);
        if (failure == ChatFailure.invalidKey) {
          _recordKeyStatus(ChatKeyStatus.invalid);
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

  /// 라운드 하나의 사용량을 넘긴다. 기다리지 않고, 실패해도 답에 영향을 주지 않는다.
  void _recordUsage(
    String questionKey,
    int round,
    ModelRequest request,
    TokenUsage? usage,
  ) {
    if (usage == null) return;
    final record = ChatUsageRecord(
      at: _clock.now(),
      questionKey: questionKey,
      vendor: _model.vendor,
      model: request.model,
      fastMode: request.fastMode,
      purpose: ChatUsagePurpose.chat,
      round: round,
      temporary: false,
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
      cacheReadTokens: usage.cacheReadTokens,
      cacheWriteTokens: usage.cacheWriteTokens,
      reasoningTokens: usage.reasoningTokens,
    );
    unawaited(
      Future.sync(() => _usage.record(record)).catchError((Object _) {}),
    );
  }

  /// 키 상태를 남긴다(§7.3). 기다리지 않고, 실패해도 답에 영향을 주지 않는다.
  /// stale 한 질문은 부르지 않는다(부르는 쪽이 확인).
  void _recordKeyStatus(ChatKeyStatus status) {
    unawaited(
      Future.sync(() => _settings.setKeyStatus(status)).catchError((Object _) {}),
    );
  }

  /// 사진이 한도를 넘기면 사진 없이 오류 결과로 바꾼다.
  ToolResult _capped(ToolResult result) {
    final count = result.images.length;
    if (count == 0) return result;
    if (_imagesSent + count > maxImagesPerConversation) {
      return const ToolResult(json: _photoLimitJson, isError: true);
    }
    _imagesSent += count;
    return result;
  }

  static ChatFailure _failureOf(ChatModelErrorKind kind) => switch (kind) {
    ChatModelErrorKind.invalidKey => ChatFailure.invalidKey,
    ChatModelErrorKind.rateLimited => ChatFailure.rateLimited,
    ChatModelErrorKind.overloaded => ChatFailure.overloaded,
    ChatModelErrorKind.network => ChatFailure.network,
    ChatModelErrorKind.quotaExceeded => ChatFailure.quotaExceeded,
    ChatModelErrorKind.modelUnavailable => ChatFailure.modelUnavailable,
    ChatModelErrorKind.server => ChatFailure.unknown,
  };

  String _systemPrompt() {
    final now = _clock.now();
    final today = DateFormat('yyyy-MM-dd (E)', 'ko').format(now);
    return '너는 사용자의 개인 기록 앱 Life Tool 안의 도우미다. '
        '오늘은 $today, 시간대는 ${now.timeZoneName} 이다.\n'
        '사용자의 일기 · 걸음 수 · 알람 기상 기록을 도구로 찾아보고, 찾은 기록에 근거해서만 답한다.\n'
        '기록에서 찾지 못한 것은 추측하지 말고 "기록에서 찾지 못했어요"라고 말한다.\n'
        '날짜는 사용자의 말("지난주", "어제")을 오늘 기준으로 바꿔 도구에 넘긴다.\n'
        '한국어로, 마크다운 없이 짧은 평문으로 답한다.';
  }
}
