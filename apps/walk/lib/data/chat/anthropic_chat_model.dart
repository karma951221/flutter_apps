import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../../domain/chat/attachment/chat_attachment.dart';
import '../../domain/chat/chat_model.dart';
import '../../domain/chat/chat_model_rules.dart';
import '../../domain/chat/chat_trace.dart';
import '../../domain/chat/chat_vendor.dart';
import 'chat_request_limits.dart';
import 'sse_lines.dart';
import 'vendor_error.dart';

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
    @visibleForTesting bool? progressNotes,
  }) : _progressNotes = progressNotes ?? progressNotesDefault;

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

  final bool _progressNotes;

  /// V2 청구 확인 전에는 false. true 면 thinking.display=updates + beta 헤더 + 노트 방출.
  static const progressNotesDefault = false;

  @override
  bool get progressNotes => _progressNotes;

  /// 본문 top-level `cache_control`(자동 캐시, V4). 블록 단위 표시는 두지 않는다.
  static const _promptCache = true;

  static const _fallbackBeta = 'server-side-fallback-2026-07-01';
  static const _notesBeta = 'thinking-display-updates-2026-08-18';
  static const _thinkingParam = {'type': 'adaptive', 'display': 'updates'};

  /// V1: thinking.display 를 받는 모델 접두사. 밖이면 thinking 키를 보내지 않는다.
  /// 같은 이름이거나 `접두사-` 로 이어질 때만 — `claude-sonnet-50` 은 아니다.
  static const _progressNoteModels = ['claude-opus-5', 'claude-sonnet-5'];

  /// 끊긴 응답의 마지막 thinking 블록에 서버가 넣는 문구(V3). 노트로 보이지 않는다.
  static const _interruptedNote =
      'This part of the response was interrupted before it finished.';

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
          _kindFor(
            status,
            (await readVendorError(response, abortTrigger)).type,
          ),
        );
      }
      yield* _parse(
        untilAbort(response.stream, abortTrigger),
        request.model,
        notes: _notes(request),
      );
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

  /// 이 요청에서 노트를 받는가 — 켰고 그 모델이 thinking.display 를 받는다(R4).
  bool _notes(ModelRequest request) =>
      _progressNotes &&
      _progressNoteModels.any(
        (p) => request.model == p || request.model.startsWith('$p-'),
      );

  Map<String, String> _headers(ModelRequest request) {
    final betas = [
      if (supportsFallbacksOf(request.model)) _fallbackBeta,
      if (_notes(request)) _notesBeta,
      if (_fast(request)) ?fastModeBeta,
    ];
    return {
      'x-api-key': request.apiKey,
      'anthropic-version': _apiVersion,
      // 실을 beta 가 없으면(옛 모델) 헤더도 보내지 않는다.
      if (betas.isNotEmpty) 'anthropic-beta': betas.join(','),
      'content-type': 'application/json',
    };
  }

  String _body(ModelRequest request) => jsonEncode({
    'model': request.model,
    'max_tokens': chatMaxOutputTokens,
    'stream': true,
    if (supportsEffortOf(vendor, request.model))
      'output_config': {'effort': 'low'},
    if (_fast(request)) ...fastModeFields,
    if (_notes(request)) 'thinking': _thinkingParam,
    if (supportsFallbacksOf(request.model)) 'fallbacks': 'default',
    if (_promptCache) 'cache_control': {'type': 'ephemeral'},
    'system': request.system,
    'messages': [for (final m in request.messages) _message(m, request.model)],
    'tools': [for (final t in request.tools) _tool(t)],
  });

  // 중립 → Messages API

  /// [model] 은 이번 요청의 모델. 같은 모델이 만든 턴만 원본 블록(thinking 서명
  /// 포함)을 그대로 돌려보낸다.
  static Map<String, Object?> _message(ChatMessage message, String model) =>
      switch (message) {
        // 첨부가 없으면 문자열 그대로(프롬프트 캐시 접두 보존).
        UserMessage(:final text, :final attachments) => {
          'role': 'user',
          'content': attachments.isEmpty
              ? text
              : [
                  for (final a in attachments) _attachment(a),
                  {'type': 'text', 'text': text},
                ],
        },
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

  static Map<String, Object?> _attachment(ChatAttachment attachment) =>
      switch (attachment) {
        ImageAttachment(:final mediaType, :final bytes) => {
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': mediaType,
            'data': base64Encode(bytes),
          },
        },
        PdfAttachment(:final bytes) => {
          'type': 'document',
          'source': {
            'type': 'base64',
            'media_type': 'application/pdf',
            'data': base64Encode(bytes),
          },
        },
        TextAttachment() => {
          'type': 'text',
          'text': textAttachmentBlock(attachment),
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

  /// 진행 노트 하나 + 계측(글자 수만).
  Iterable<ModelEvent> _note(String text) sync* {
    if (_trace.enabled) {
      _trace.mark(ChatTraceMark.progress, {'chars': text.length});
    }
    yield ModelEvent.progress(text);
  }

  /// 노트로 낼 글. 비었거나 중단 문구면 null.
  static String? _noteOf(String raw) {
    final text = raw.trim();
    return text.isEmpty || text == _interruptedNote ? null : text;
  }

  /// [notes] 면 thinking 블록 글을 진행 노트로 낸다.
  Stream<ModelEvent> _parse(
    Stream<List<int>> bytes,
    String model, {
    required bool notes,
  }) async* {
    final blocks = <int, Map<String, Object?>>{};
    final jsonBuffers = <int, StringBuffer>{};
    // thinking 블록마다 아직 내지 않은 누적 노트가 있는가(중단 문구의 접두사라
    // 보류한 경우).
    final heldNotes = <int>{};
    // thinking 블록마다 마지막으로 낸 노트(공백만 더한 delta 로 같은 글을 다시 내지 않게).
    final lastNotes = <int, String>{};
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
          switch (block) {
            case {'type': 'thinking' || 'redacted_thinking'}:
              yield const ModelEvent.thinking();
            case {'type': 'tool_use'}:
              jsonBuffers[index] = StringBuffer();
              if (block case {
                'id': final String id,
                'name': final String name,
              }) {
                yield ModelEvent.toolCallStarted(id: id, name: name);
              }
          }
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
              final thinking =
                  '${block['thinking'] ?? ''}${delta['thinking'] ?? ''}';
              block['thinking'] = thinking;
              if (!notes) break;
              final text = thinking.trim();
              if (text.isEmpty) break;
              if (_interruptedNote.startsWith(text)) {
                heldNotes.add(index);
                break;
              }
              heldNotes.remove(index);
              if (lastNotes[index] == text) break;
              lastNotes[index] = text;
              yield* _note(text);
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
          if (heldNotes.remove(index) && block != null) {
            final note = _noteOf('${block['thinking'] ?? ''}');
            if (note != null) yield* _note(note);
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
            if (block case {
              'id': final String id,
              'name': final String name,
              'input': final Map<Object?, Object?> input,
            }) {
              yield ModelEvent.toolCallReady(
                id: id,
                name: name,
                input: Map<String, Object?>.from(input),
              );
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
