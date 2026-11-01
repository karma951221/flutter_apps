import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../../domain/chat/chat_model.dart';
import '../../domain/chat/chat_trace.dart';
import '../../domain/chat/chat_vendor.dart';
import 'sse_lines.dart';

/// 한 Anthropic 턴의 원본 content 블록(thinking · 서명 포함). 다음 요청에 그대로
/// 돌려보내야 서명이 깨지지 않는다. toString 은 블록 개수만.
final class AnthropicTurnState implements VendorTurnState {
  const AnthropicTurnState({required this.model, required this.content});

  /// 요청한 모델 id.
  @override
  final String model;

  final List<Map<String, Object?>> content;

  @override
  ChatVendor get vendor => ChatVendor.anthropic;

  @override
  String toString() => 'AnthropicTurnState(blocks: ${content.length})';
}

/// Anthropic Messages API 를 SSE 로 읽는다. 예외에는 키나 응답 본문을 담지 않는다.
///
/// 중립 [ChatMessage] ↔ Messages API 변환도 여기서 한다. 요청 단위 "서버 저장"
/// 옵션(OpenAI `store` 같은 것)은 Messages API 에 없다 — 보존은 조직 설정이다
/// (C2). 그래서 본문에 `store` · `metadata` 를 넣지 않는다.
@LazySingleton(as: ChatModel)
class AnthropicChatModel implements ChatModel {
  AnthropicChatModel(http.Client client, ChatTrace trace)
    : this.withTimeouts(client, trace);

  /// 테스트가 짧은 대기 시간을 넣을 때 쓴다.
  AnthropicChatModel.withTimeouts(
    this._client,
    this._trace, {
    this.responseTimeout = const Duration(seconds: 60),
    this.idleTimeout = const Duration(seconds: 90),
  });

  final http.Client _client;
  final ChatTrace _trace;

  /// 요청을 보내고 응답(상태 줄)이 오기까지.
  final Duration responseTimeout;

  /// SSE 줄 사이 최대 간격. 서버는 오래 생각하는 동안에도 ping 이벤트를 보낸다.
  final Duration idleTimeout;

  static final _endpoint = Uri.parse('https://api.anthropic.com/v1/messages');

  @override
  ChatVendor get vendor => ChatVendor.anthropic;

  /// 구독을 끊으면 진행 중인 HTTP 요청 · 응답을 닫는다(abortTrigger). 끊은 뒤에는
  /// 이벤트도 오류도 내지 않는다. 정상 · 오류 종료로 끝난 뒤의 취소는 abort 가 아니다.
  ///
  /// `async*` 의 `finally` 에서 abort 하지 않는다 — `async*` 는 취소돼도 `send` 를
  /// 기다리는 동안 `finally` 에 닿지 않는다.
  @override
  Stream<ModelEvent> stream(ModelRequest request) {
    final abort = Completer<void>();
    var cancelled = false;
    var settled = false;
    StreamSubscription<ModelEvent>? inner;
    late final StreamController<ModelEvent> out;
    out = StreamController<ModelEvent>(
      onListen: () => inner = _run(request, abort).listen(
        (e) {
          if (!cancelled) out.add(e);
        },
        onError: (Object e, StackTrace s) {
          // _run 의 오류는 마지막이다 — 요청은 이미 끝났다.
          settled = true;
          if (!cancelled) out.addError(e, s);
        },
        onDone: () {
          settled = true;
          if (!cancelled) unawaited(out.close());
        },
      ),
      onCancel: () {
        cancelled = true;
        if (!settled && !abort.isCompleted) {
          abort.complete();
          if (_trace.enabled) _trace.mark(ChatTraceMark.abort);
        }
        // 기다리지 않는다 — 구독자 cancel 이 묶이지 않게. 취소 뒤 _run 이 던지는
        // 오류(RequestAbortedException 등)는 버린다.
        inner?.cancel().ignore();
      },
    );
    return out.stream;
  }

  /// [abort] 는 [stream] 의 것. 구독 취소 말고 상태 줄 시간 초과에서도 끝낸다.
  Stream<ModelEvent> _run(ModelRequest request, Completer<void> abort) async* {
    final abortTrigger = abort.future;
    try {
      if (_trace.enabled) {
        _trace.mark(ChatTraceMark.req, {
          'vendor': vendor.name,
          'model': request.model,
          'fast': request.fastMode,
        });
      }
      final response =
          await abortableSend(
            _client,
            method: 'POST',
            url: _endpoint,
            headers: _headers(request),
            body: _body(request),
            abortTrigger: abortTrigger,
          ).timeout(
            responseTimeout,
            onTimeout: () {
              // 버린 요청이 뒤에서 계속 돌지 않게 끊는다. 사용자 취소가 아니므로
              // trace abort 는 찍지 않는다(시간 초과는 network 오류로 드러난다).
              if (!abort.isCompleted) abort.complete();
              throw TimeoutException('response', responseTimeout);
            },
          );
      if (_trace.enabled) _trace.mark(ChatTraceMark.head);
      final status = response.statusCode;
      if (status < 200 || status >= 300) {
        // 본문은 읽지도 담지도 않는다.
        unawaited(response.stream.drain<void>().catchError((_) {}));
        throw ChatModelException(_kindForStatus(status));
      }
      yield* _parse(_untilAbort(response.stream, abortTrigger), request.model);
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

  static Map<String, String> _headers(ModelRequest request) => {
    'x-api-key': request.apiKey,
    'anthropic-version': '2026-10-21',
    'anthropic-beta': 'server-side-fallback-2026-07-01',
    'content-type': 'application/json',
  };

  static String _body(ModelRequest request) => jsonEncode({
    'model': request.model,
    'max_tokens': 16000,
    'stream': true,
    'output_config': {'effort': 'low'},
    'fallbacks': 'default',
    'system': request.system,
    'messages': [for (final m in request.messages) _message(m)],
    'tools': [for (final t in request.tools) _tool(t)],
  });

  /// [abort] 가 끝나면 바이트 구독을 끊고 스트림을 닫는다. `async*` 는 `await for`
  /// 로 다음 바이트를 기다리는 동안 취소를 알아채지 못하므로, 클라이언트가
  /// abortTrigger 를 따르지 않아도 여기서 끊는다.
  static Stream<List<int>> _untilAbort(
    Stream<List<int>> bytes,
    Future<void> abort,
  ) {
    StreamSubscription<List<int>>? sub;
    late final StreamController<List<int>> out;
    out = StreamController<List<int>>(
      sync: true,
      onListen: () {
        sub = bytes.listen(out.add, onError: out.addError, onDone: out.close);
        unawaited(
          abort.whenComplete(() {
            if (out.isClosed) return;
            sub?.cancel().ignore();
            unawaited(out.close());
          }),
        );
      },
      onPause: () => sub?.pause(),
      onResume: () => sub?.resume(),
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  // 중립 → Messages API

  static Map<String, Object?> _message(ChatMessage message) =>
      switch (message) {
        UserMessage(:final text) => {'role': 'user', 'content': text},
        AssistantMessage(vendorState: final AnthropicTurnState state) => {
          'role': 'assistant',
          'content': state.content,
        },
        // 상태가 없거나(멈춘 턴) 다른 벤더의 것이면 parts 로 다시 만든다(thinking 없음).
        AssistantMessage(:final parts) => {
          'role': 'assistant',
          'content': [for (final p in parts) _part(p)],
        },
        ToolResultsMessage(:final results) => {
          'role': 'user',
          'content': [for (final r in results) _toolResult(r)],
        },
      };

  static Map<String, Object?> _part(AssistantPart part) => switch (part) {
    TextPart(:final text) => {'type': 'text', 'text': text},
    ToolCallPart(:final id, :final name, :final input) => {
      'type': 'tool_use',
      'id': id,
      'name': name,
      'input': input,
    },
  };

  static Map<String, Object?> _toolResult(ToolResultPart result) => {
    'type': 'tool_result',
    'tool_use_id': result.callId,
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

  static Map<String, Object?> _tool(ToolSpec tool) => {
    'name': tool.name,
    'description': tool.description,
    'input_schema': tool.parameters,
  };

  static ChatModelErrorKind _kindForStatus(int status) => switch (status) {
    401 || 403 => ChatModelErrorKind.invalidKey,
    429 => ChatModelErrorKind.rateLimited,
    529 => ChatModelErrorKind.overloaded,
    _ => ChatModelErrorKind.server,
  };

  static StopKind _stopOf(String? reason) => switch (reason) {
    'end_turn' || null => StopKind.endTurn,
    'tool_use' => StopKind.toolUse,
    'refusal' => StopKind.refusal,
    'max_tokens' => StopKind.maxTokens,
    _ => StopKind.other,
  };

  /// `message_start.message.usage` 를 읽는다. 모양이 어긋나면 null(답은 계속).
  /// 캐시 필드는 없거나 null 이면 0.
  static TokenUsage? _startUsage(Object? message) {
    if (message is! Map) return null;
    final usage = message['usage'];
    if (usage is! Map) return null;
    final input = usage['input_tokens'];
    final output = usage['output_tokens'];
    final cacheWrite = usage['cache_creation_input_tokens'] ?? 0;
    final cacheRead = usage['cache_read_input_tokens'] ?? 0;
    if (input is! int ||
        output is! int ||
        cacheWrite is! int ||
        cacheRead is! int) {
      return null;
    }
    return TokenUsage(
      inputTokens: input,
      outputTokens: output,
      cacheReadTokens: cacheRead,
      cacheWriteTokens: cacheWrite,
    );
  }

  /// Messages API content → 중립 parts. thinking · redacted_thinking 등은 빼고
  /// vendorState 에만 둔다.
  static List<AssistantPart> _partsOf(List<Map<String, Object?>> content) => [
    for (final block in content)
      if (block['type'] == 'text')
        AssistantPart.text(block['text'] as String? ?? '')
      else if (block['type'] == 'tool_use')
        AssistantPart.toolCall(
          id: block['id']! as String,
          name: block['name']! as String,
          input: Map<String, Object?>.from(
            block['input'] as Map? ?? const <String, Object?>{},
          ),
        ),
  ];

  Stream<ModelEvent> _parse(Stream<List<int>> bytes, String model) async* {
    final blocks = <int, Map<String, Object?>>{};
    final jsonBuffers = <int, StringBuffer>{};
    String? stopReason;
    TokenUsage? usage;
    int? lastOutputTokens;
    var completed = false;

    // 이벤트 하나를 처리한다.
    Iterable<ModelEvent> dispatch(String name, String payload) sync* {
      Map<String, Object?> json;
      try {
        json = (jsonDecode(payload) as Map).cast<String, Object?>();
      } on FormatException {
        throw const ChatModelException(ChatModelErrorKind.server);
      }
      switch (name) {
        case 'message_start':
          usage = _startUsage(json['message']);
        case 'content_block_start':
          final index = json['index'] as int;
          final block = Map<String, Object?>.from(json['content_block'] as Map);
          blocks[index] = block;
          if (_trace.enabled) {
            _trace.mark(ChatTraceMark.blockStart, {
              'kind': block['type'],
              if (block['type'] == 'tool_use') 'tool': block['name'],
            });
          }
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
              if (_trace.enabled) {
                _trace.mark(ChatTraceMark.textDelta, {'chars': text.length});
              }
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
          if (_trace.enabled) {
            _trace.mark(ChatTraceMark.blockStop, {'kind': block?['type']});
          }
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
          final deltaUsage = json['usage'];
          if (deltaUsage is Map && deltaUsage['output_tokens'] is int) {
            lastOutputTokens = deltaUsage['output_tokens'] as int;
          }
        case 'message_stop':
          completed = true;
          final indexes = blocks.keys.toList()..sort();
          final content = [for (final i in indexes) blocks[i]!];
          final start = usage;
          final stop = _stopOf(stopReason);
          final finalUsage = start == null || lastOutputTokens == null
              ? start
              : TokenUsage(
                  inputTokens: start.inputTokens,
                  outputTokens: lastOutputTokens!,
                  cacheReadTokens: start.cacheReadTokens,
                  cacheWriteTokens: start.cacheWriteTokens,
                );
          if (_trace.enabled) {
            _trace.mark(ChatTraceMark.msgStop, {
              'stop': stop.name,
              if (finalUsage != null) ...{
                'in': finalUsage.inputTokens,
                'out': finalUsage.outputTokens,
                'cacheRead': finalUsage.cacheReadTokens,
                'cacheWrite': finalUsage.cacheWriteTokens,
                'reasoning': ?finalUsage.reasoningTokens,
              },
            });
          }
          yield ModelEvent.completed(
            message: AssistantMessage(
              parts: _partsOf(content),
              vendorState: AnthropicTurnState(model: model, content: content),
            ),
            stop: stop,
            usage: finalUsage,
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

    var firstSeen = false;
    try {
      await for (final e in sseEvents(bytes, idleTimeout: idleTimeout)) {
        if (!firstSeen) {
          firstSeen = true;
          if (_trace.enabled) _trace.mark(ChatTraceMark.first);
        }
        yield* Stream.fromIterable(dispatch(e.event, e.data).toList());
      }
      if (!completed) {
        throw const ChatModelException(ChatModelErrorKind.network);
      }
    } on ChatModelException {
      rethrow;
    } on SocketException {
      throw const ChatModelException(ChatModelErrorKind.network);
    } on http.ClientException {
      throw const ChatModelException(ChatModelErrorKind.network);
    } on TimeoutException {
      throw const ChatModelException(ChatModelErrorKind.network);
    } on TypeError {
      // 이벤트 모양이 문서와 다르다(필드 타입이 어긋난 캐스트).
      throw const ChatModelException(ChatModelErrorKind.server);
    }
  }
}
