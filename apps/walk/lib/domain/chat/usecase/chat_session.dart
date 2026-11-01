import 'dart:async';

import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

import '../chat_model.dart';
import '../chat_settings.dart';
import '../chat_usage_log.dart';
import '../tool/life_tools.dart';
import '../tool/tool_result.dart';

part 'chat_session.freezed.dart';

enum ChatFailure {
  noKey,
  invalidKey,
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

/// 한 대화. 질문마다 Claude 를 부르고, 도구를 요청하면 실행해 결과를 돌려준다.
///
/// 대화 기록은 덧붙이기만 한다(assistant 턴의 vendorState 도 그대로).
/// 질문이 실패하거나 중간에 구독이 끊기면 그 질문에서 덧붙인 메시지를 되돌린다.
@lazySingleton
class ChatSession {
  ChatSession(
    this._model,
    this._tools,
    this._settings,
    this._clock,
    this._usage,
    this._ids,
  );

  final ChatModel _model;
  final LifeTools _tools;
  final ChatSettings _settings;
  final Clock _clock;
  final ChatUsageLog _usage;
  final IdGenerator _ids;

  static const maxRounds = 8;

  /// 키 기획 ① 동안 쓰는 모델 id. 요청마다 [ModelRequest.model] 로 넘긴다.
  /// 키 기획 ③ 이 모델 카탈로그로 바꾸며 지운다.
  static const interimModel = 'claude-opus-5-5';

  /// 한 대화에 보내는 사진 수 한도. 지난 메시지는 고치지 않으므로(thinking 서명이
  /// 깨진다) 보낸 사진은 매 요청에 다시 실린다 — 대신 한도에서 막는다.
  static const maxImagesPerConversation = 12;

  static const _photoLimitJson =
      '{"error":"photo_limit_reached","hint":"새 대화를 시작하면 다시 사진을 볼 수 있어요"}';

  final _messages = <ChatMessage>[];
  bool _busy = false;

  /// 이 대화에서 보낸 사진 수. 되돌린 질문의 사진은 세지 않는다.
  int _imagesSent = 0;

  /// [reset] 마다 올린다. 진행 중인 질문은 자기 세대가 바뀌면 조용히 멈춘다.
  int _generation = 0;

  /// 한 번에 하나. 진행 중에 부르면 [StateError].
  Stream<ChatEvent> ask(String question) {
    if (_busy) throw StateError('ChatSession.ask is already running');
    _busy = true;
    return _run(question, _generation);
  }

  /// 대화 비우기. 진행 중이어도 부를 수 있다 — 그 질문은 더 덧붙이지도,
  /// 이벤트를 내지도 않고 끝나며, 바로 다음 [ask] 를 받을 수 있다.
  void reset() {
    _generation++;
    _messages.clear();
    _imagesSent = 0;
    _busy = false;
  }

  Stream<ChatEvent> _run(String question, int generation) async* {
    bool stale() => generation != _generation;
    final start = _messages.length;
    final imagesAtStart = _imagesSent;
    var completed = false;
    try {
      final apiKey = await _settings.apiKey();
      if (stale()) return;
      if (apiKey == null) {
        yield const ChatEvent.failed(ChatFailure.noKey);
        return;
      }
      final system = _systemPrompt();
      final tools = _tools.definitions;
      final cited = <String>{};
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
        await for (final event in _model.stream(request)) {
          if (stale()) return;
          switch (event) {
            case ModelTextDelta(:final text):
              yield ChatEvent.text(text);
            case ModelCompleted():
              done = event;
            case ModelThinking() ||
                ModelProgress() ||
                ModelToolCallStarted() ||
                ModelToolCallReady():
              break;
          }
        }
        if (stale()) return;
        if (done == null) {
          throw const ChatModelException(ChatModelErrorKind.network);
        }
        _recordUsage(questionKey, round, request, done.usage);
        _messages.add(done.message);

        switch (done.stop) {
          case StopKind.toolUse:
            final results = <ToolResultPart>[];
            for (final part in done.message.parts) {
              if (part is! ToolCallPart) continue;
              yield ChatEvent.toolStarted(part.name);
              final result = await _tools.run(part.name, part.input);
              if (stale()) return;
              cited.addAll(result.entryIds);
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
            yield ChatEvent.finished(citedEntryIds: List.of(cited));
            return;
        }
      }
      yield const ChatEvent.failed(ChatFailure.tooManySteps);
    } on ChatModelException catch (e) {
      if (!stale()) yield ChatEvent.failed(_failureOf(e.kind));
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
    ChatModelErrorKind.server ||
    ChatModelErrorKind.quotaExceeded ||
    ChatModelErrorKind.modelUnavailable => ChatFailure.unknown,
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
