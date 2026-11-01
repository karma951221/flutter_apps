import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../../domain/chat/chat_model.dart';
import '../../domain/chat/chat_model_rules.dart';
import '../../domain/chat/chat_trace.dart';
import '../../domain/chat/chat_vendor.dart';
import '../../domain/chat/tool/tool_result.dart';
import 'chat_request_limits.dart';
import 'sse_lines.dart';
import 'vendor_error.dart';

/// 한 OpenAI 턴의 원본 output 항목(reasoning 의 encrypted_content · message ·
/// function_call). 같은 모델의 다음 요청 `input` 에 그대로 돌려보낸다 — 서버
/// 저장을 끄므로(`store: false`) 추론은 이 암호문으로만 이어진다.
/// toString 은 항목 개수만.
final class OpenAiTurnState implements VendorTurnState {
  const OpenAiTurnState({required this.model, required this.items});

  @override
  ChatVendor get vendor => ChatVendor.openai;

  /// 이 턴을 요청한 모델 id.
  @override
  final String model;

  final List<Map<String, Object?>> items;

  @override
  String toString() => 'OpenAiTurnState(items: ${items.length})';
}

/// OpenAI Responses API 를 SSE 로 읽는다. 예외에는 키나 응답 본문을 담지 않는다.
///
/// 서버 저장은 늘 끈다(`store: false`, `previous_response_id` 없음) — 매번
/// 대화 전체를 보내고, 추론은 `reasoning.encrypted_content` 로 왕복한다(O1).
///
/// 결과는 `response.completed` · `incomplete` · `failed` 의 마지막 `response`
/// 객체에서 다시 읽는다(G14). 중간 이벤트는 글 조각 · 계측에만 쓴다 — 이벤트
/// 이름 · 순서가 확인 전(O7)이어도 결과 · vendorState 가 맞게.
///
/// 구체 타입으로 등록한다 — domain 은 [ChatModelRegistry] 로만 받는다.
@lazySingleton
class OpenAiChatModel implements ChatModel {
  OpenAiChatModel(http.Client client, ChatTrace trace)
    : this.withTimeouts(client, trace);

  /// 테스트가 짧은 대기 시간 · 다른 지원 표를 넣을 때 쓴다.
  OpenAiChatModel.withTimeouts(
    this._client,
    this._trace, {
    this.responseTimeout = const Duration(seconds: 60),
    this.idleTimeout = const Duration(seconds: 90),
    this.listTimeout = const Duration(seconds: 10),
    this.imagesInToolOutput = false,
    @visibleForTesting this.fastSpecs = fastModeSpecs,
  });

  final http.Client _client;
  final ChatTrace _trace;

  /// 요청을 보내고 응답(상태 줄)이 오기까지.
  final Duration responseTimeout;

  /// SSE 줄 사이 최대 간격.
  final Duration idleTimeout;

  /// [listModels] 요청부터 본문 끝까지.
  final Duration listTimeout;

  /// 도구 결과 사진을 `function_call_output.output` 배열에 싣는가(O2 · G13).
  /// 확인 전 기본은 false — 결과는 글, 사진은 결과들 뒤 `role: user` 입력 하나.
  final bool imagesInToolOutput;

  /// 빠른 출력 지원 표. 테스트가 바꿔 넣는다.
  final Map<ChatVendor, List<FastModeSpec>> fastSpecs;

  static final base = Uri.parse('https://api.openai.com/v1/');
  static final _responsesEndpoint = base.resolve('responses');
  static final _modelsEndpoint = base.resolve('models');

  /// 빠른 처리 필드(O5, 추정). 지원 표([fastModeSpecs])가 비어 있는 동안 실리지
  /// 않는다.
  @visibleForTesting
  static const Map<String, Object?> fastModeFields = {
    'service_tier': 'priority', // O5
  };

  /// 이미지 거절 오류 코드(O6, 추정). 틀리면 `server` 로 떨어질 뿐이다(G15).
  @visibleForTesting
  static const Set<String> imageUnsupportedCodes = {
    'unsupported_image_input', // O6
  };

  /// 도구 결과 사진을 뒤따르는 user 입력에 실을 때 앞에 붙는 글.
  static const _toolImagesLabel = '(도구 결과 사진)';

  @override
  ChatVendor get vendor => ChatVendor.openai;

  /// 추론 요약을 노트로 내는 것은 청구 확인 뒤(V6) — 지금은 내지 않는다.
  @override
  bool get progressNotes => false;

  // listModels

  /// `GET /v1/models`. 판정은 상태 코드만(2xx ok · 401/403 invalidKey · 그 밖
  /// unreachable). 오류 본문은 읽지 않는다. 목록은 관대하게 읽는다 — 모양이
  /// 어긋난 항목은 건너뛰고, 본문을 못 읽으면 빈 목록(키는 맞다). 이 끝점은 쪽을
  /// 나누지 않는다(한 번에 전부).
  @override
  Future<ModelListResult> listModels(String apiKey) async {
    final abort = Completer<void>();
    try {
      return await _list(apiKey, abort.future).timeout(
        listTimeout,
        onTimeout: () {
          if (!abort.isCompleted) abort.complete();
          return const ModelListResult.unreachable();
        },
      );
    } catch (_) {
      // SocketException · ClientException 등. 던지지 않는다.
      return const ModelListResult.unreachable();
    }
  }

  Future<ModelListResult> _list(String apiKey, Future<void> abort) async {
    final request = http.AbortableRequest(
      'GET',
      _modelsEndpoint,
      abortTrigger: abort,
    )..headers['authorization'] = 'Bearer $apiKey';
    final response = await _client.send(request);
    final status = response.statusCode;
    if (status < 200 || status >= 300) {
      unawaited(response.stream.drain<void>().catchError((_) {}));
      return status == 401 || status == 403
          ? const ModelListResult.invalidKey()
          : const ModelListResult.unreachable();
    }
    final body = await response.stream.toBytes();
    Object? json;
    try {
      json = jsonDecode(utf8.decode(body));
    } on FormatException {
      return const ModelListResult.ok([]);
    }
    final data = json is Map ? json['data'] : null;
    if (data is! List) return const ModelListResult.ok([]);
    return ModelListResult.ok([
      for (final item in data)
        if (item is Map && item['id'] is String)
          ModelInfo(
            id: item['id'] as String,
            displayName: item['id'] as String,
            createdAt: switch (item['created']) {
              final int seconds => DateTime.fromMillisecondsSinceEpoch(
                seconds * 1000,
                isUtc: true,
              ),
              _ => null,
            },
            // 능력은 목록에 없다 — 규칙(chat_model_rules)이 정한다.
          ),
    ]);
  }

  // stream

  /// 취소 계약은 [abortableStream] 이 지킨다 — 구독을 끊으면 요청 · 응답을 닫고
  /// 그 뒤 아무것도 내지 않는다.
  @override
  Stream<ModelEvent> stream(ModelRequest request) =>
      abortableStream((abort) => _run(request, abort), trace: _trace);

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
            url: _responsesEndpoint,
            headers: {
              'authorization': 'Bearer ${request.apiKey}',
              'content-type': 'application/json',
            },
            body: _body(request),
            abortTrigger: abortTrigger,
          ).timeout(
            responseTimeout,
            onTimeout: () {
              // 버린 요청이 뒤에서 계속 돌지 않게 끊는다(사용자 취소 아님).
              if (!abort.isCompleted) abort.complete();
              throw TimeoutException('response', responseTimeout);
            },
          );
      if (_trace.enabled) _trace.mark(ChatTraceMark.head);
      final status = response.statusCode;
      if (status < 200 || status >= 300) {
        // 본문에서 error.type · code 만 읽고 나머지(message 등)는 버린다.
        throw ChatModelException(
          _kindFor(status, await readVendorError(response, abortTrigger)),
        );
      }
      yield* _parse(untilAbort(response.stream, abortTrigger), request.model);
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

  /// 빠른 처리를 이 요청에 싣는가 — 켰고 지원 표가 그 모델을 안다(O5).
  bool _fast(ModelRequest request) =>
      request.fastMode &&
      fastModeOf(vendor, request.model, specs: fastSpecs) != null;

  String _body(ModelRequest request) => jsonEncode({
    'model': request.model,
    'instructions': request.system,
    'input': [for (final m in request.messages) ..._input(m, request.model)],
    'tools': [for (final t in request.tools) _tool(t)],
    'stream': true,
    'store': false,
    'include': ['reasoning.encrypted_content'],
    'max_output_tokens': chatMaxOutputTokens,
    if (supportsEffortOf(vendor, request.model)) 'reasoning': {'effort': 'low'},
    if (_fast(request)) ...fastModeFields,
  });

  // 중립 → Responses input

  /// [model] 은 이번 요청의 모델. 같은 모델이 만든 턴만 원본 항목(추론 암호문
  /// 포함)을 그대로 돌려보낸다.
  List<Map<String, Object?>> _input(ChatMessage message, String model) =>
      switch (message) {
        UserMessage(:final text) => [
          {'role': 'user', 'content': text},
        ],
        AssistantMessage(vendorState: final OpenAiTurnState state)
            when state.model == model =>
          state.items,
        // 상태가 없거나(멈춘 턴) 다른 벤더 · 다른 모델의 것이면 parts 로 다시
        // 만든다(reasoning 없음).
        AssistantMessage(:final parts) => [for (final p in parts) _part(p)],
        ToolResultsMessage(:final results) => _toolResults(results),
      };

  static Map<String, Object?> _part(AssistantPart part) => switch (part) {
    TextPart(:final text) => {
      'type': 'message',
      'role': 'assistant',
      'content': [
        {'type': 'output_text', 'text': text},
      ],
    },
    ToolCallPart(:final id, :final name, :final input) => {
      'type': 'function_call',
      'call_id': id,
      'name': name,
      'arguments': jsonEncode(input),
    },
  };

  List<Map<String, Object?>> _toolResults(List<ToolResultPart> results) {
    Map<String, Object?> image(ToolImage i) => {
      'type': 'input_image',
      'image_url': 'data:${i.mediaType};base64,${base64Encode(i.bytes)}',
    };

    if (imagesInToolOutput) {
      return [
        for (final r in results)
          {
            'type': 'function_call_output',
            'call_id': r.callId,
            'output': r.images.isEmpty
                ? r.json
                : [
                    {'type': 'input_text', 'text': r.json},
                    for (final i in r.images) image(i),
                  ],
          },
      ];
    }
    final images = [
      for (final r in results)
        for (final i in r.images) image(i),
    ];
    return [
      for (final r in results)
        {'type': 'function_call_output', 'call_id': r.callId, 'output': r.json},
      if (images.isNotEmpty)
        {
          'role': 'user',
          'content': [
            {'type': 'input_text', 'text': _toolImagesLabel},
            ...images,
          ],
        },
    ];
  }

  static Map<String, Object?> _tool(ToolSpec tool) => {
    'type': 'function',
    'name': tool.name,
    'description': tool.description,
    'parameters': tool.parameters,
    'strict': false,
  };

  // 오류

  /// `error.code` → `error.type` → 상태 코드 순(O6). SSE 의 오류는 [status] 없이.
  static ChatModelErrorKind _kindFor(int? status, VendorError error) =>
      _kindOfCode(error.code) ??
      _kindOfCode(error.type) ??
      switch (status) {
        401 || 403 => ChatModelErrorKind.invalidKey,
        404 => ChatModelErrorKind.modelUnavailable,
        429 => ChatModelErrorKind.rateLimited,
        503 => ChatModelErrorKind.overloaded,
        _ => ChatModelErrorKind.server,
      };

  static ChatModelErrorKind? _kindOfCode(String? code) => switch (code) {
    null => null,
    'invalid_api_key' => ChatModelErrorKind.invalidKey,
    'insufficient_quota' => ChatModelErrorKind.quotaExceeded,
    'rate_limit_exceeded' => ChatModelErrorKind.rateLimited,
    'model_not_found' => ChatModelErrorKind.modelUnavailable,
    _ when imageUnsupportedCodes.contains(code) =>
      ChatModelErrorKind.imagesUnsupported,
    _ => null,
  };

  // Responses → 중립

  /// `response.usage`. 정수가 아니면 null(답은 계속). 세부 항목이 없으면
  /// 캐시 0 · 추론 null.
  static TokenUsage? _usageOf(Object? usage) {
    if (usage is! Map) return null;
    final input = usage['input_tokens'];
    final output = usage['output_tokens'];
    final inputDetails = usage['input_tokens_details'];
    final outputDetails = usage['output_tokens_details'];
    final cached = inputDetails is Map ? inputDetails['cached_tokens'] ?? 0 : 0;
    final reasoning = outputDetails is Map
        ? outputDetails['reasoning_tokens']
        : null;
    if (input is! int ||
        output is! int ||
        cached is! int ||
        (reasoning != null && reasoning is! int)) {
      return null;
    }
    return TokenUsage(
      inputTokens: input,
      outputTokens: output,
      cacheReadTokens: cached,
      reasoningTokens: reasoning as int?,
    );
  }

  /// 잘린(`incomplete`) 응답에서 다음 요청에 돌려보낼 수 없는 항목을 뺀다 —
  /// 끝나지 않은 function_call(`arguments` 가 잘렸을 수 있다)과, 뒤따르는 항목이
  /// 없는 끝의 reasoning(같은 모델의 다음 요청이 거절할 수 있다). 다른 상태면 그대로.
  static List<Map<String, Object?>> _keptItems(
    Object? status,
    List<Map<String, Object?>> items,
  ) {
    if (status != 'incomplete') return items;
    final kept = [
      for (final item in items)
        if (item['type'] != 'function_call' || item['status'] == 'completed')
          item,
    ];
    while (kept.isNotEmpty && kept.last['type'] == 'reasoning') {
      kept.removeLast();
    }
    return kept;
  }

  /// 마지막 `response` 객체 → completed 이벤트.
  ModelEvent _completedOf(Map<String, Object?> response, String model) {
    final output = response['output'] as List? ?? const [];
    final items = _keptItems(response['status'], [
      for (final item in output) Map<String, Object?>.from(item as Map),
    ]);
    final parts = <AssistantPart>[];
    var refused = false;
    var called = false;
    for (final item in items) {
      switch (item['type']) {
        case 'message':
          for (final content in item['content'] as List? ?? const []) {
            final c = content as Map;
            switch (c['type']) {
              case 'output_text':
                parts.add(AssistantPart.text(c['text'] as String? ?? ''));
              case 'refusal':
                // 거절 글은 parts 에 넣지 않는다.
                refused = true;
            }
          }
        case 'function_call':
          called = true;
          final arguments = item['arguments'] as String? ?? '';
          Object? input;
          try {
            input = arguments.isEmpty
                ? <String, Object?>{}
                : jsonDecode(arguments);
          } on FormatException {
            throw const ChatModelException(ChatModelErrorKind.server);
          }
          parts.add(
            AssistantPart.toolCall(
              id: item['call_id']! as String,
              name: item['name']! as String,
              input: Map<String, Object?>.from(input! as Map),
            ),
          );
        // reasoning 등은 parts 에 넣지 않고 vendorState 에만 둔다.
      }
    }
    final details = response['incomplete_details'];
    final stop = called
        ? StopKind.toolUse
        : refused
        ? StopKind.refusal
        : switch (response['status']) {
            'completed' => StopKind.endTurn,
            'incomplete'
                when details is Map &&
                    details['reason'] == 'max_output_tokens' =>
              StopKind.maxTokens,
            _ => StopKind.other,
          };
    final usage = _usageOf(response['usage']);
    if (_trace.enabled) {
      _trace.mark(ChatTraceMark.msgStop, {
        'stop': stop.name,
        if (usage != null) ...{
          'in': usage.inputTokens,
          'out': usage.outputTokens,
          'cacheRead': usage.cacheReadTokens,
          'cacheWrite': usage.cacheWriteTokens,
          'reasoning': ?usage.reasoningTokens,
        },
      });
    }
    return ModelEvent.completed(
      message: AssistantMessage(
        parts: parts,
        vendorState: OpenAiTurnState(model: model, items: items),
      ),
      stop: stop,
      usage: usage,
    );
  }

  /// 끝난 함수 호출 항목 → toolCallReady. 끝나지 않았거나(잘림) 인자를 못 읽으면
  /// null — 결과 판정은 completed 가 한다.
  static ModelEvent? _readyOf(Object? item) {
    if (item case {
      'type': 'function_call',
      'status': 'completed',
      'call_id': final String id,
      'name': final String name,
      'arguments': final String arguments,
    }) {
      try {
        final input = arguments.isEmpty
            ? const <String, Object?>{}
            : jsonDecode(arguments);
        if (input is Map) {
          return ModelEvent.toolCallReady(
            id: id,
            name: name,
            input: Map<String, Object?>.from(input),
          );
        }
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  /// 계측용 항목 종류 이름.
  static Object? _kindOfItem(Object? type) => switch (type) {
    'reasoning' => 'thinking',
    'message' => 'text',
    'function_call' => 'tool_use',
    _ => type,
  };

  Stream<ModelEvent> _parse(Stream<List<int>> bytes, String model) async* {
    var completed = false;

    Iterable<ModelEvent> dispatch(String name, String payload) sync* {
      Map<String, Object?> json;
      try {
        json = (jsonDecode(payload) as Map).cast<String, Object?>();
      } on FormatException {
        throw const ChatModelException(ChatModelErrorKind.server);
      }
      switch (name) {
        case 'response.output_text.delta':
          final text = json['delta'] as String? ?? '';
          if (_trace.enabled) {
            _trace.mark(ChatTraceMark.textDelta, {'chars': text.length});
          }
          yield ModelEvent.textDelta(text);
        case 'response.output_item.added':
          final item = json['item'];
          final type = item is Map ? item['type'] : null;
          if (_trace.enabled) {
            _trace.mark(ChatTraceMark.blockStart, {
              'kind': _kindOfItem(type),
              if (type == 'function_call' && item is Map) 'tool': item['name'],
            });
          }
          // 진행 이벤트(ModelEvent 방출 규칙). 결과는 completed 에서 다시 읽으므로
          // 모양이 어긋나면 이벤트만 건너뛴다.
          switch (item) {
            case {'type': 'reasoning'}:
              yield const ModelEvent.thinking();
            case {
              'type': 'function_call',
              'call_id': final String id,
              'name': final String name,
            }:
              yield ModelEvent.toolCallStarted(id: id, name: name);
          }
        case 'response.output_item.done':
          final item = json['item'];
          if (_trace.enabled) {
            _trace.mark(ChatTraceMark.blockStop, {
              'kind': _kindOfItem(item is Map ? item['type'] : null),
            });
          }
          if (_readyOf(item) case final ready?) yield ready;
        case 'response.completed' || 'response.incomplete':
          completed = true;
          final response = (json['response']! as Map).cast<String, Object?>();
          yield _completedOf(response, model);
        case 'response.failed':
          final response = json['response'];
          final error = response is Map ? response['error'] : null;
          throw ChatModelException(
            _kindFor(null, vendorErrorOf({'error': error})),
          );
        case 'error':
          // 모양 확인 전(O6·O7) — 최상위 code/type 이거나 error 안.
          final inner = json['error'];
          throw ChatModelException(
            _kindFor(
              null,
              vendorErrorOf({'error': inner is Map ? inner : json}),
            ),
          );
      }
    }

    var firstSeen = false;
    try {
      await for (final e in sseEvents(
        bytes,
        idleTimeout: idleTimeout,
        // O7: event 줄이 없으면 payload 의 type 으로.
        typeFallback: true,
      )) {
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
