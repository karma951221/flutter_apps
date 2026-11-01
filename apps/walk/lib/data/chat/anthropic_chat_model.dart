import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../../domain/chat/chat_model.dart';
import '../../domain/chat/chat_model_rules.dart';
import '../../domain/chat/chat_trace.dart';
import '../../domain/chat/chat_vendor.dart';
import 'sse_lines.dart';

/// 한 Anthropic 턴의 원본 content 블록(thinking · 서명 포함). 다음 요청에 그대로
/// 돌려보내야 서명이 깨지지 않는다. toString 은 블록 개수만.
final class AnthropicTurnState implements VendorTurnState {
  const AnthropicTurnState({required this.model, required this.content});

  /// 이 턴을 실제로 답한 모델 id(`message_start.message.model`). 대체 모델
  /// (`fallbacks`)이 답했을 수 있다. 응답에 없으면 요청한 id.
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
///
/// 구체 타입으로 등록한다 — domain 은 [ChatModelRegistry] 로만 받는다.
@lazySingleton
class AnthropicChatModel implements ChatModel {
  AnthropicChatModel(http.Client client, ChatTrace trace)
    : this.withTimeouts(client, trace);

  /// 테스트가 짧은 대기 시간을 넣을 때 쓴다.
  AnthropicChatModel.withTimeouts(
    this._client,
    this._trace, {
    this.responseTimeout = const Duration(seconds: 60),
    this.idleTimeout = const Duration(seconds: 90),
    this.listTimeout = const Duration(seconds: 10),
    @visibleForTesting this.fastSpecs = fastModeSpecs,
  });

  final http.Client _client;
  final ChatTrace _trace;

  /// 요청을 보내고 응답(상태 줄)이 오기까지.
  final Duration responseTimeout;

  /// SSE 줄 사이 최대 간격. 서버는 오래 생각하는 동안에도 ping 이벤트를 보낸다.
  final Duration idleTimeout;

  /// [listModels] 한 쪽의 요청부터 본문 끝까지.
  final Duration listTimeout;

  /// 빠른 출력 지원 표. 테스트가 바꿔 넣는다.
  final Map<ChatVendor, List<FastModeSpec>> fastSpecs;

  /// fast mode 요청 필드 · 베타 헤더(A2). 확인 전 값은 문서 기억에 따른
  /// 자리표시이고 지원 표([fastModeSpecs])가 비어 있어 실리지 않는다.
  @visibleForTesting
  static const Map<String, Object?> fastModeFields = {'speed': 'fast'};
  @visibleForTesting
  static const String? fastModeBeta = null; // A2

  /// 목록을 받는 최대 쪽 수.
  static const _maxModelPages = 5;

  static final _endpoint = Uri.parse('https://api.anthropic.com/v1/messages');
  static final _modelsEndpoint = Uri.parse(
    'https://api.anthropic.com/v1/models',
  );
  static const _apiVersion = '2026-10-21';

  /// 오류 본문에서 `error.type` 을 읽을 때의 상한. 넘으면 상태 코드로만 판정한다.
  static const _errorBodyLimit = 16 * 1024;
  static const _errorBodyTimeout = Duration(seconds: 2);

  @override
  ChatVendor get vendor => ChatVendor.anthropic;

  /// `GET /v1/models`. 판정은 상태 코드만(2xx ok · 401/403 invalidKey · 그 밖
  /// unreachable). 오류 본문은 읽지 않는다. 목록은 관대하게 읽는다 — 모양이
  /// 어긋난 항목은 건너뛰고, 본문을 못 읽으면 빈 목록(키는 맞다).
  ///
  /// `has_more == true` 이고 `last_id` 가 String 이면 `after_id` 로 다음 쪽을
  /// 받는다(최대 [_maxModelPages] 쪽, 쪽마다 [listTimeout]). 둘째 쪽부터는 실패해도
  /// 받은 쪽까지 ok(A1).
  @override
  Future<ModelListResult> listModels(String apiKey) async {
    final models = <ModelInfo>[];
    String? after;
    for (var page = 0; page < _maxModelPages; page++) {
      final result = await _listPage(apiKey, after);
      switch (result) {
        case (ModelListOk(models: final got), final next):
          models.addAll(got);
          if (next == null) return ModelListResult.ok(models);
          after = next;
        case (final failed, _):
          return page == 0 ? failed : ModelListResult.ok(models);
      }
    }
    return ModelListResult.ok(models);
  }

  /// 한 쪽. (결과, 다음 쪽 after_id). 던지지 않는다.
  Future<(ModelListResult, String?)> _listPage(
    String apiKey,
    String? after,
  ) async {
    const unreachable = (ModelListResult.unreachable(), null);
    final abort = Completer<void>();
    try {
      return await _list(apiKey, after, abort.future).timeout(
        listTimeout,
        onTimeout: () {
          if (!abort.isCompleted) abort.complete();
          return unreachable;
        },
      );
    } catch (_) {
      // SocketException · ClientException 등. 던지지 않는다.
      return unreachable;
    }
  }

  Future<(ModelListResult, String?)> _list(
    String apiKey,
    String? after,
    Future<void> abort,
  ) async {
    final request = http.AbortableRequest(
      'GET',
      _modelsEndpoint.replace(
        queryParameters: {'limit': '1000', 'after_id': ?after},
      ),
      abortTrigger: abort,
    )..headers.addAll({'x-api-key': apiKey, 'anthropic-version': _apiVersion});
    final response = await _client.send(request);
    final status = response.statusCode;
    if (status < 200 || status >= 300) {
      unawaited(response.stream.drain<void>().catchError((_) {}));
      return (
        status == 401 || status == 403
            ? const ModelListResult.invalidKey()
            : const ModelListResult.unreachable(),
        null,
      );
    }
    final body = await response.stream.toBytes();
    final (models, next) = _pageOf(body);
    return (ModelListResult.ok(models), next);
  }

  /// 한 쪽의 (모델, 다음 쪽 after_id).
  static (List<ModelInfo>, String?) _pageOf(Uint8List body) {
    Object? json;
    try {
      json = jsonDecode(utf8.decode(body));
    } on FormatException {
      return (const [], null);
    }
    if (json is! Map) return (const [], null);
    final next = switch ((json['has_more'], json['last_id'])) {
      (true, final String last) => last,
      _ => null,
    };
    final data = json['data'];
    if (data is! List) return (const [], next);
    return (_modelsOf(data), next);
  }

  static List<ModelInfo> _modelsOf(List<Object?> data) {
    return [
      for (final item in data)
        if (item is Map && item['id'] is String)
          ModelInfo(
            id: item['id'] as String,
            displayName: switch (item['display_name']) {
              final String name => name,
              _ => item['id'] as String,
            },
            createdAt: switch (item['created_at']) {
              final String at => DateTime.tryParse(at),
              _ => null,
            },
            // §10.1: Claude 목록은 전부 채팅 · 도구 · 이미지.
            supportsTools: true,
            supportsImages: true,
          ),
    ];
  }

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
        // 본문에서 error.type 하나만 읽고 나머지(message 등)는 버린다.
        throw ChatModelException(
          _kindFor(status, await _errorType(response, abortTrigger)),
        );
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

  /// 빠른 출력을 이 요청에 싣는가 — 켰고 지원 표가 그 모델을 안다(A2).
  bool _fast(ModelRequest request) =>
      request.fastMode &&
      fastModeOf(vendor, request.model, specs: fastSpecs) != null;

  Map<String, String> _headers(ModelRequest request) => {
    'x-api-key': request.apiKey,
    'anthropic-version': _apiVersion,
    'anthropic-beta': [
      'server-side-fallback-2026-07-01',
      if (_fast(request)) ?fastModeBeta,
    ].join(','),
    'content-type': 'application/json',
  };

  String _body(ModelRequest request) => jsonEncode({
    'model': request.model,
    'max_tokens': 16000,
    'stream': true,
    if (supportsEffortOf(vendor, request.model))
      'output_config': {'effort': 'low'},
    if (_fast(request)) ...fastModeFields,
    'fallbacks': 'default',
    'system': request.system,
    'messages': [for (final m in request.messages) _message(m, request.model)],
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

  /// [model] 은 이번 요청의 모델. 같은 모델이 만든 턴만 원본 블록(thinking 서명
  /// 포함)을 그대로 돌려보낸다.
  static Map<String, Object?> _message(ChatMessage message, String model) =>
      switch (message) {
        UserMessage(:final text) => {'role': 'user', 'content': text},
        AssistantMessage(vendorState: final AnthropicTurnState state)
            when state.model == model =>
          {'role': 'assistant', 'content': state.content},
        // 상태가 없거나(멈춘 턴) 다른 벤더 · 다른 모델의 것이면 parts 로 다시
        // 만든다(thinking 없음, A4).
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

  /// 오류 응답에서 error.type 만 꺼낸다. [_errorBodyLimit] · [_errorBodyTimeout] 을
  /// 넘거나 JSON 이 아니면 null. 나머지는 버린다. [abort] 가 끝나면 읽기를 멈춘다.
  static Future<String?> _errorType(
    http.StreamedResponse response, [
    Future<void>? abort,
  ]) async {
    final buffer = BytesBuilder(copy: false);
    final done = Completer<bool>();
    void finish(bool complete) {
      if (!done.isCompleted) done.complete(complete);
    }

    late final StreamSubscription<List<int>> sub;
    sub = response.stream.listen(
      (chunk) {
        buffer.add(chunk);
        if (buffer.length > _errorBodyLimit) {
          // 더 받지 않는다 — 넘친 본문은 바로 끊는다.
          unawaited(sub.cancel().catchError((_) {}));
          finish(false);
        }
      },
      onError: (Object _) => finish(false),
      onDone: () => finish(true),
      cancelOnError: true,
    );
    unawaited(abort?.whenComplete(() => finish(false)));
    final complete = await done.future.timeout(
      _errorBodyTimeout,
      onTimeout: () => false,
    );
    unawaited(sub.cancel().catchError((_) {}));
    if (!complete) return null;
    try {
      final json = jsonDecode(utf8.decode(buffer.takeBytes()));
      if (json case {'error': {'type': final String type}}) return type;
    } on FormatException {
      // JSON 이 아니다 — 상태 코드로 판정한다.
    }
    return null;
  }

  /// [type](error.type)이 먼저, 모르면 상태 코드. SSE error 이벤트는 [status] 없이.
  static ChatModelErrorKind _kindFor(int? status, String? type) =>
      switch (type) {
        'authentication_error' ||
        'permission_error' => ChatModelErrorKind.invalidKey,
        'billing_error' => ChatModelErrorKind.quotaExceeded, // K2
        'not_found_error' => ChatModelErrorKind.modelUnavailable,
        'rate_limit_error' => ChatModelErrorKind.rateLimited,
        'overloaded_error' => ChatModelErrorKind.overloaded,
        _ => switch (status) {
          401 || 403 => ChatModelErrorKind.invalidKey,
          402 => ChatModelErrorKind.quotaExceeded,
          404 => ChatModelErrorKind.modelUnavailable,
          429 => ChatModelErrorKind.rateLimited,
          529 => ChatModelErrorKind.overloaded,
          _ => ChatModelErrorKind.server,
        },
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
    // 실제로 답한 모델. 대체 모델이면 요청한 [model] 과 다르다.
    var answeredBy = model;

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
          final message = json['message'];
          usage = _startUsage(message);
          if (message is Map && message['model'] is String) {
            answeredBy = message['model'] as String;
          }
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
              vendorState: AnthropicTurnState(
                model: answeredBy,
                content: content,
              ),
            ),
            stop: stop,
            usage: finalUsage,
          );
        case 'error':
          final error = json['error'];
          final type = error is Map ? error['type'] : null;
          throw ChatModelException(
            _kindFor(null, type is String ? type : null),
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
