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
  );

  final ChatModelRegistry _registry;
  final LifeTools _tools;
  final ChatSettings _settings;
  final ChatModelChoice _choice;
  final Clock _clock;
  final ChatUsageLog _usage;
  final IdGenerator _ids;
  final ChatTrace _trace;

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
    try {
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
      final model = _registry.of(target.vendor);
      // 질문 동안 고정한다 — 그 사이 모델 · 빠른 출력을 바꾸면 다음 질문부터.
      final fastMode = _choice.fastModeOn;
      // 이미지 거절(imagesUnsupported)을 받으면 이 질문의 남은 요청은 사진 없이.
      var images = _choice.supportsImages;
      var retriedWithoutImages = false;
      final system = _systemPrompt();
      final questionKey = _ids.newId();
      _messages.add(ChatMessage.user(question));

      for (var round = 1; round <= maxRounds; round++) {
        ModelCompleted? done;
        // 이미지 거절이면 같은 라운드를 사진 없이 한 번만 다시 보낸다.
        while (true) {
          final request = ModelRequest(
            apiKey: apiKey,
            model: target.model,
            fastMode: fastMode,
            system: system,
            messages: _requestMessages(images: images),
            tools: _tools.definitionsFor(images: images),
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
                  _turnText.write(text);
                  yield ChatEvent.text(text);
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
                  );
                case ModelThinking() ||
                    ModelProgress() ||
                    ModelToolCallStarted() ||
                    ModelToolCallReady():
                  break;
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
            await _choice.markNoImages(target.model);
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
              final capped = _capped(result, images: images);
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
            _contextTarget = target;
            _recordKeyStatus(ChatKeyStatus.valid, apiKey);
            yield ChatEvent.finished(citedEntryIds: List.of(_turnCited));
            return;
        }
      }
      yield const ChatEvent.failed(ChatFailure.tooManySteps);
    } on ChatModelException catch (e) {
      if (!stale()) {
        var failure = _failureOf(e.kind);
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

  /// 라운드 하나의 사용량을 넘긴다. 기다리지 않고, 실패해도 답에 영향을 주지 않는다.
  void _recordUsage(
    String questionKey,
    int round,
    ChatTarget requestTarget,
    ModelRequest request,
    TokenUsage? usage,
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
    );
    unawaited(
      Future.sync(() => _usage.record(record)).catchError((Object _) {}),
    );
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

  static ChatFailure _failureOf(ChatModelErrorKind kind) => switch (kind) {
    ChatModelErrorKind.invalidKey => ChatFailure.invalidKey,
    ChatModelErrorKind.rateLimited => ChatFailure.rateLimited,
    ChatModelErrorKind.overloaded => ChatFailure.overloaded,
    ChatModelErrorKind.network => ChatFailure.network,
    ChatModelErrorKind.quotaExceeded => ChatFailure.quotaExceeded,
    ChatModelErrorKind.modelUnavailable => ChatFailure.modelUnavailable,
    // 이미지 거절은 사진 없이 한 번 다시 보낸다([_run]). 또 나면 unknown.
    ChatModelErrorKind.server ||
    ChatModelErrorKind.imagesUnsupported => ChatFailure.unknown,
  };

  String _systemPrompt() {
    final now = _clock.now();
    final today = DateFormat('yyyy-MM-dd (E)', 'ko').format(now);
    return '너는 사용자의 개인 기록 앱 Life Tool 안의 도우미다. '
        '오늘은 $today, 시간대는 ${now.timeZoneName} 이다.\n'
        '사용자의 일기 · 걸음 수 · 알람 기상 기록을 도구로 찾아보고, 찾은 기록에 근거해서만 답한다.\n'
        '기록에서 찾지 못한 것은 추측하지 말고 "기록에서 찾지 못했어요"라고 말한다.\n'
        '날짜는 사용자의 말("지난주", "어제")을 오늘 기준으로 바꿔 도구에 넘긴다.\n'
        '사진 보기 도구가 없으면 사진은 볼 수 없다고 짧게 답한다.\n'
        '한국어로, 마크다운 없이 짧은 평문으로 답한다.';
  }
}
