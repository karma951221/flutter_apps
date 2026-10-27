import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../../domain/chat/chat_model.dart';

/// Anthropic Messages API 를 SSE 로 읽는다. 예외에는 키나 응답 본문을 담지 않는다.
@LazySingleton(as: ChatModel)
class AnthropicChatModel implements ChatModel {
  AnthropicChatModel(this._client);

  final http.Client _client;

  static final _endpoint = Uri.parse('https://api.anthropic.com/v1/messages');

  @override
  Stream<ModelEvent> stream({
    required String apiKey,
    required String system,
    required List<Map<String, Object?>> messages,
    required List<Map<String, Object?>> tools,
  }) async* {
    final request = http.Request('POST', _endpoint)
      ..headers.addAll({
        'x-api-key': apiKey,
        'anthropic-version': '2026-10-21',
        'anthropic-beta': 'server-side-fallback-2026-07-01',
        'content-type': 'application/json',
      })
      ..body = jsonEncode({
        'model': 'claude-opus-5-5',
        'max_tokens': 16000,
        'stream': true,
        'output_config': {'effort': 'low'},
        'fallbacks': 'default',
        'system': system,
        'messages': messages,
        'tools': tools,
      });

    try {
      final response = await _client.send(request);
      final status = response.statusCode;
      if (status < 200 || status >= 300) {
        // 본문은 읽지도 담지도 않는다.
        unawaited(response.stream.drain<void>().catchError((_) {}));
        throw ChatModelException(_kindForStatus(status));
      }
      yield* _parse(response.stream);
    } on ChatModelException {
      rethrow;
    } on SocketException {
      throw const ChatModelException(ChatModelErrorKind.network);
    } on http.ClientException {
      throw const ChatModelException(ChatModelErrorKind.network);
    } on TimeoutException {
      throw const ChatModelException(ChatModelErrorKind.network);
    }
  }

  static ChatModelErrorKind _kindForStatus(int status) => switch (status) {
    401 || 403 => ChatModelErrorKind.invalidKey,
    429 => ChatModelErrorKind.rateLimited,
    529 => ChatModelErrorKind.overloaded,
    _ => ChatModelErrorKind.server,
  };

  Stream<ModelEvent> _parse(Stream<List<int>> bytes) async* {
    final blocks = <int, Map<String, Object?>>{};
    final jsonBuffers = <int, StringBuffer>{};
    String? stopReason;
    String? event;
    final data = StringBuffer();
    var hasData = false;

    final lines = bytes.transform(utf8.decoder).transform(const LineSplitter());

    // 빈 줄을 만나면 모인 이벤트를 처리한다.
    Iterable<ModelEvent> dispatch() sync* {
      final name = event;
      final payload = data.toString();
      event = null;
      data.clear();
      final had = hasData;
      hasData = false;
      if (name == null || !had) return;
      Map<String, Object?> json;
      try {
        json = jsonDecode(payload) as Map<String, Object?>;
      } on FormatException {
        throw const ChatModelException(ChatModelErrorKind.server);
      }
      switch (name) {
        case 'content_block_start':
          final index = json['index'] as int;
          final block = Map<String, Object?>.from(json['content_block'] as Map);
          blocks[index] = block;
          if (block['type'] == 'tool_use') jsonBuffers[index] = StringBuffer();
        case 'content_block_delta':
          final index = json['index'] as int;
          final delta = json['delta'] as Map;
          final block = blocks[index];
          if (block == null) break;
          switch (delta['type']) {
            case 'text_delta':
              final text = delta['text'] as String? ?? '';
              block['text'] = '${block['text'] ?? ''}$text';
              yield ModelEvent.textDelta(text);
            case 'thinking_delta':
              block['thinking'] =
                  '${block['thinking'] ?? ''}${delta['thinking'] ?? ''}';
            case 'signature_delta':
              block['signature'] =
                  '${block['signature'] ?? ''}${delta['signature'] ?? ''}';
            case 'input_json_delta':
              (jsonBuffers[index] ??= StringBuffer()).write(
                delta['partial_json'] ?? '',
              );
          }
        case 'content_block_stop':
          final index = json['index'] as int;
          final buffer = jsonBuffers.remove(index);
          final block = blocks[index];
          if (buffer != null && block != null) {
            final text = buffer.toString();
            try {
              block['input'] = text.isEmpty
                  ? <String, Object?>{}
                  : jsonDecode(text);
            } on FormatException {
              throw const ChatModelException(ChatModelErrorKind.server);
            }
          }
        case 'message_delta':
          final delta = json['delta'];
          if (delta is Map && delta['stop_reason'] is String) {
            stopReason = delta['stop_reason'] as String;
          }
        case 'message_stop':
          final indexes = blocks.keys.toList()..sort();
          yield ModelEvent.completed(
            content: [for (final i in indexes) blocks[i]!],
            stopReason: stopReason ?? 'end_turn',
          );
        case 'error':
          final error = json['error'];
          final type = error is Map ? error['type'] : null;
          throw ChatModelException(
            type == 'overloaded_error'
                ? ChatModelErrorKind.overloaded
                : ChatModelErrorKind.server,
          );
      }
    }

    try {
      await for (final line in lines) {
        if (line.isEmpty) {
          yield* Stream.fromIterable(dispatch().toList());
        } else if (line.startsWith('event:')) {
          event = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          if (hasData) data.write('\n');
          var value = line.substring(5);
          if (value.startsWith(' ')) value = value.substring(1);
          data.write(value);
          hasData = true;
        }
      }
      yield* Stream.fromIterable(dispatch().toList());
    } on ChatModelException {
      rethrow;
    } on SocketException {
      throw const ChatModelException(ChatModelErrorKind.network);
    } on http.ClientException {
      throw const ChatModelException(ChatModelErrorKind.network);
    } on TimeoutException {
      throw const ChatModelException(ChatModelErrorKind.network);
    }
  }
}
