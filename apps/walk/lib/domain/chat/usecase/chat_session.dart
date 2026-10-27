import 'dart:convert';

import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

import '../chat_model.dart';
import '../chat_settings.dart';
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
/// 대화 기록은 덧붙이기만 한다(assistant content 의 thinking 서명도 그대로).
/// 질문이 실패하거나 중간에 구독이 끊기면 그 질문에서 덧붙인 메시지를 되돌린다.
@lazySingleton
class ChatSession {
  ChatSession(this._model, this._tools, this._settings, this._clock);

  final ChatModel _model;
  final LifeTools _tools;
  final ChatSettings _settings;
  final Clock _clock;

  static const maxRounds = 8;

  final _messages = <Map<String, Object?>>[];
  bool _busy = false;

  /// 한 번에 하나. 진행 중에 부르면 [StateError].
  Stream<ChatEvent> ask(String question) {
    if (_busy) throw StateError('ChatSession.ask is already running');
    _busy = true;
    return _run(question);
  }

  /// 대화 비우기.
  void reset() => _messages.clear();

  Stream<ChatEvent> _run(String question) async* {
    final start = _messages.length;
    var completed = false;
    try {
      final apiKey = await _settings.apiKey();
      if (apiKey == null) {
        yield const ChatEvent.failed(ChatFailure.noKey);
        return;
      }
      final system = _systemPrompt();
      final tools = _tools.definitions;
      final cited = <String>{};
      _messages.add({'role': 'user', 'content': question});

      for (var round = 1; round <= maxRounds; round++) {
        ModelCompleted? done;
        await for (final event in _model.stream(
          apiKey: apiKey,
          system: system,
          messages: List.unmodifiable(_messages),
          tools: tools,
        )) {
          switch (event) {
            case ModelTextDelta(:final text):
              yield ChatEvent.text(text);
            case ModelCompleted():
              done = event;
          }
        }
        if (done == null) {
          throw const ChatModelException(ChatModelErrorKind.network);
        }
        _messages.add({'role': 'assistant', 'content': done.content});

        switch (done.stopReason) {
          case 'tool_use':
            final results = <Map<String, Object?>>[];
            for (final block in done.content) {
              if (block['type'] != 'tool_use') continue;
              final name = block['name']! as String;
              yield ChatEvent.toolStarted(name);
              final input = (block['input'] as Map?)?.cast<String, Object?>();
              final result = await _tools.run(name, input ?? const {});
              cited.addAll(result.entryIds);
              results.add(_toolResult(block['id']! as String, result));
            }
            _messages.add({'role': 'user', 'content': results});
          case 'refusal':
            yield const ChatEvent.failed(ChatFailure.refused);
            return;
          default:
            completed = true;
            yield ChatEvent.finished(citedEntryIds: List.of(cited));
            return;
        }
      }
      yield const ChatEvent.failed(ChatFailure.tooManySteps);
    } on ChatModelException catch (e) {
      yield ChatEvent.failed(_failureOf(e.kind));
    } catch (_) {
      yield const ChatEvent.failed(ChatFailure.unknown);
    } finally {
      if (!completed) _messages.removeRange(start, _messages.length);
      _busy = false;
    }
  }

  static Map<String, Object?> _toolResult(String id, ToolResult result) => {
    'type': 'tool_result',
    'tool_use_id': id,
    'is_error': result.isError,
    'content': [
      {'type': 'text', 'text': result.json},
      for (final image in result.images)
        {
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': image.mediaType,
            'data': base64Encode(image.bytes),
          },
        },
    ],
  };

  static ChatFailure _failureOf(ChatModelErrorKind kind) => switch (kind) {
    ChatModelErrorKind.invalidKey => ChatFailure.invalidKey,
    ChatModelErrorKind.rateLimited => ChatFailure.rateLimited,
    ChatModelErrorKind.overloaded => ChatFailure.overloaded,
    ChatModelErrorKind.network => ChatFailure.network,
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
