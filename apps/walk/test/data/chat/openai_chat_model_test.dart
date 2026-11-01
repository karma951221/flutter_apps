import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:walk/data/chat/anthropic_chat_model.dart';
import 'package:walk/data/chat/chat_request_limits.dart';
import 'package:walk/data/chat/openai_chat_model.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_model_rules.dart';
import 'package:walk/domain/chat/chat_trace.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/tool/tool_result.dart';

import '../../support/chat_fixtures.dart';
import '../../support/recording_chat_trace.dart';

String sse(String event, Map<String, Object?> data) =>
    'event: $event\ndata: ${jsonEncode(data)}\n\n';

MockClient clientOf(
  List<String> chunks, {
  int status = 200,
  void Function(http.BaseRequest, String)? onRequest,
}) {
  return MockClient.streaming((request, body) async {
    final text = await utf8.decodeStream(body);
    onRequest?.call(request, text);
    return http.StreamedResponse(
      Stream.fromIterable(chunks.map(utf8.encode)),
      status,
    );
  });
}

MockClient fixtureClient(String name) =>
    clientOf([chatFixture('openai/$name')]);

/// 지원하는 모델(effort 규칙이 참).
const _model = 'gpt-5.5';

ModelRequest request({
  String apiKey = 'sk-proj-test',
  String model = _model,
  bool fastMode = false,
  List<ChatMessage> messages = const [],
  List<ToolSpec> tools = const [],
}) => ModelRequest(
  apiKey: apiKey,
  model: model,
  fastMode: fastMode,
  system: 'sys',
  messages: messages,
  tools: tools,
);

OpenAiChatModel modelOf(
  http.Client client, {
  ChatTrace trace = const NoopChatTrace(),
}) => OpenAiChatModel(client, trace);

Future<List<ModelEvent>> run(http.Client client, [ModelRequest? r]) =>
    modelOf(client).stream(r ?? request()).toList();

Future<ModelCompleted> completedOf(String fixture, [ModelRequest? r]) async {
  final events = await run(fixtureClient(fixture), r);
  return events.whereType<ModelCompleted>().single;
}

String _completed({
  List<Map<String, Object?>> output = const [],
  Object? usage,
}) => sse('response.completed', {
  'type': 'response.completed',
  'response': {
    'id': 'resp_x',
    'status': 'completed',
    'output': output,
    'usage': ?usage,
  },
});

/// 요청 본문을 잡는 끝난 응답 하나.
MockClient capture(void Function(Map<String, dynamic> body) onBody) => clientOf(
  [_completed()],
  onRequest: (_, b) => onBody(jsonDecode(b) as Map<String, dynamic>),
);

Future<Map<String, dynamic>> bodyOf(
  ModelRequest r, {
  OpenAiChatModel Function(http.Client)? make,
}) async {
  late Map<String, dynamic> body;
  final client = capture((b) => body = b);
  await (make ?? modelOf)(client).stream(r).toList();
  return body;
}

/// 다른 벤더의 상태.
class _OtherState implements VendorTurnState {
  @override
  ChatVendor get vendor => ChatVendor.anthropic;
  @override
  String get model => _model;
}

/// `send` 가 받은 요청을 잡아 두는 손 가짜. 응답은 테스트가 [respond] 로 준다.
/// 실제 IOClient 처럼 abortTrigger 가 끝나면 아직 안 끝난 send 를
/// RequestAbortedException 으로 끝낸다.
class _HangingClient extends http.BaseClient {
  http.BaseRequest? request;
  final _response = Completer<http.StreamedResponse>();

  Future<void> get abortTrigger => (request! as http.Abortable).abortTrigger!;

  void respond(Stream<List<int>> bytes, [int status = 200]) =>
      _response.complete(http.StreamedResponse(bytes, status));

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    this.request = request;
    if (request case http.Abortable(:final abortTrigger?)) {
      unawaited(
        abortTrigger.whenComplete(() {
          if (!_response.isCompleted) {
            _response.completeError(http.RequestAbortedException(request.url));
          }
        }),
      );
    }
    return _response.future;
  }
}

/// 끝났는지 지금 바로 본다(1ms 안).
Future<bool> _completedSoon(Future<void> f) => f
    .timeout(const Duration(milliseconds: 1))
    .then((_) => true, onError: (Object _) => false);

final _image = ToolImage(
  mediaType: 'image/jpeg',
  bytes: Uint8List.fromList([1, 2, 3]),
);

const _tool = ToolSpec(
  name: 'search_diary',
  description: '일기 찾기',
  parameters: {
    'type': 'object',
    'properties': {
      'query': {'type': 'string'},
    },
    'required': ['query'],
  },
);

void main() {
  test('vendor 는 openai', () {
    expect(
      modelOf(MockClient((_) async => http.Response('', 200))).vendor,
      ChatVendor.openai,
    );
  });

  test('Authorization Bearer 헤더 · POST /v1/responses · stream true', () async {
    late http.BaseRequest req;
    late Map<String, dynamic> body;
    final client = clientOf(
      [_completed()],
      onRequest: (r, b) {
        req = r;
        body = jsonDecode(b) as Map<String, dynamic>;
      },
    );
    await run(client, request(apiKey: 'sk-proj-abc'));

    expect(req.method, 'POST');
    expect(req.url, Uri.parse('https://api.openai.com/v1/responses'));
    expect(req.headers['authorization'], 'Bearer sk-proj-abc');
    expect(req.headers['content-type'], startsWith('application/json'));
    expect(
      req.headers.keys.map((k) => k.toLowerCase()),
      isNot(contains('x-api-key')),
    );
    expect(body['stream'], isTrue);
    expect(body['model'], _model);
    expect(body['max_output_tokens'], chatMaxOutputTokens);
    expect(chatMaxOutputTokens, 16000);
  });

  test('요청에 store false · include reasoning.encrypted_content 가 늘 있고 '
      'previous_response_id 가 없다', () async {
    final fast = {
      ChatVendor.openai: [
        FastModeSpec(pattern: RegExp(r'^gpt-'), priceFactor: 2),
      ],
    };
    for (final tools in [
      <ToolSpec>[],
      [_tool],
    ]) {
      for (final withImage in [false, true]) {
        for (final fastMode in [false, true]) {
          final body = await bodyOf(
            request(
              tools: tools,
              fastMode: fastMode,
              messages: [
                const ChatMessage.user('q'),
                const ChatMessage.assistant(
                  parts: [
                    AssistantPart.toolCall(id: 'c1', name: 'x', input: {}),
                  ],
                ),
                ChatMessage.toolResults([
                  ToolResultPart(
                    callId: 'c1',
                    json: '{}',
                    images: withImage ? [_image] : const [],
                  ),
                ]),
              ],
            ),
            make: (c) => OpenAiChatModel.withTimeouts(
              c,
              const NoopChatTrace(),
              fastSpecs: fast,
            ),
          );
          final reason =
              'tools=${tools.length} image=$withImage fast=$fastMode';
          expect(body['store'], isFalse, reason: reason);
          expect(body['include'], [
            'reasoning.encrypted_content',
          ], reason: reason);
          expect(
            body.containsKey('previous_response_id'),
            isFalse,
            reason: reason,
          );
        }
      }
    }
  });

  test('instructions 는 system, user 는 문자열 content', () async {
    final body = await bodyOf(
      request(messages: [const ChatMessage.user('안녕')]),
    );
    expect(body['instructions'], 'sys');
    expect(body['input'], [
      {'role': 'user', 'content': '안녕'},
    ]);
    expect(body.containsKey('system'), isFalse);
    expect(body.containsKey('messages'), isFalse);
  });

  test('ToolSpec 은 type function · parameters · strict false', () async {
    final body = await bodyOf(request(tools: [_tool]));
    expect(body['tools'], [
      {
        'type': 'function',
        'name': 'search_diary',
        'description': '일기 찾기',
        'parameters': _tool.parameters,
        'strict': false,
      },
    ]);
  });

  group('모델별 필드', () {
    test('effort 는 supportsEffortOf 가 참일 때만', () async {
      const unsupported = 'gpt-4.1';
      expect(supportsEffortOf(ChatVendor.openai, _model), isTrue);
      expect(supportsEffortOf(ChatVendor.openai, unsupported), isFalse);

      expect((await bodyOf(request()))['reasoning'], {'effort': 'low'});
      expect(
        (await bodyOf(request(model: unsupported))).containsKey('reasoning'),
        isFalse,
      );
    });

    test('fastMode 면 fastModeFields', () async {
      expect(OpenAiChatModel.fastModeFields, isNotEmpty);
      final fast = {
        ChatVendor.openai: [
          FastModeSpec(pattern: RegExp(r'^gpt-5'), priceFactor: 2),
        ],
      };
      OpenAiChatModel make(http.Client c) => OpenAiChatModel.withTimeouts(
        c,
        const NoopChatTrace(),
        fastSpecs: fast,
      );

      final on = await bodyOf(request(fastMode: true), make: make);
      for (final e in OpenAiChatModel.fastModeFields.entries) {
        expect(on[e.key], e.value);
      }
      final off = await bodyOf(request(), make: make);
      for (final key in OpenAiChatModel.fastModeFields.keys) {
        expect(off.containsKey(key), isFalse);
      }
      // 지원하지 않는 모델
      final other = await bodyOf(
        request(model: 'o5-mini', fastMode: true),
        make: make,
      );
      for (final key in OpenAiChatModel.fastModeFields.keys) {
        expect(other.containsKey(key), isFalse);
      }
    });

    test('지원 표가 비어 있으면 fastMode 여도 본문이 꺼졌을 때와 같다', () async {
      expect(fastModeSpecs[ChatVendor.openai] ?? const [], isEmpty);
      expect(await bodyOf(request(fastMode: true)), await bodyOf(request()));
    });
  });

  test(
    'stream_text.sse → textDelta 들과 completed(endTurn, TextPart, usage)',
    () async {
      final events = await run(fixtureClient('stream_text.sse'));
      final deltas = events.whereType<ModelTextDelta>().map((e) => e.text);
      expect(deltas, ['오늘은 ', '맑아요.']);
      expect(events.last, isA<ModelCompleted>());
      final done = events.last as ModelCompleted;
      expect(done.stop, StopKind.endTurn);
      expect(done.message.parts, [const AssistantPart.text('오늘은 맑아요.')]);
      expect(
        done.usage,
        const TokenUsage(
          inputTokens: 1200,
          outputTokens: 42,
          cacheReadTokens: 800,
          cacheWriteTokens: 0,
          reasoningTokens: 30,
        ),
      );
      // 진행 이벤트는 내지 않는다.
      expect(
        events.where((e) => e is! ModelTextDelta && e is! ModelCompleted),
        isEmpty,
      );
    },
  );

  test(
    'stream_tool_call.sse → toolUse, ToolCallPart(id=call_id, input 디코드)',
    () async {
      final done = await completedOf('stream_tool_call.sse');
      expect(done.stop, StopKind.toolUse);
      expect(done.message.parts, [
        const AssistantPart.toolCall(
          id: 'call_abc',
          name: 'search_diary',
          input: {'query': '산책', 'limit': 3},
        ),
      ]);
    },
  );

  test('stream_refusal.sse → refusal(글은 parts 에 없다)', () async {
    final events = await run(fixtureClient('stream_refusal.sse'));
    final done = events.whereType<ModelCompleted>().single;
    expect(done.stop, StopKind.refusal);
    expect(done.message.parts, isEmpty);
    expect(events.whereType<ModelTextDelta>(), isEmpty);
  });

  test('stream_incomplete.sse(max_output_tokens) → maxTokens', () async {
    final done = await completedOf('stream_incomplete.sse');
    expect(done.stop, StopKind.maxTokens);
    expect(done.message.parts, [const AssistantPart.text('길게 이어지던 답')]);
  });

  test('incomplete 의 다른 이유는 other', () async {
    final events = await run(
      clientOf([
        sse('response.incomplete', {
          'response': {
            'status': 'incomplete',
            'incomplete_details': {'reason': 'content_filter'},
            'output': [],
          },
        }),
      ]),
    );
    expect(events.whereType<ModelCompleted>().single.stop, StopKind.other);
  });

  group('추론 항목 왕복', () {
    test('stream_reasoning_tool.sse → vendorState 의 items 에 encrypted_content '
        '가 있고 다음 요청 input 에 그대로 돌아간다(같은 모델)', () async {
      final done = await completedOf('stream_reasoning_tool.sse');
      expect(done.stop, StopKind.toolUse);
      expect(done.message.parts, [
        const AssistantPart.text('찾아볼게요'),
        const AssistantPart.toolCall(
          id: 'call_r1',
          name: 'search_diary',
          input: {'query': '강아지'},
        ),
      ]);
      final state = done.message.vendorState! as OpenAiTurnState;
      expect(state.vendor, ChatVendor.openai);
      expect(state.model, _model);
      expect(state.items, hasLength(3));
      expect(state.items.first['encrypted_content'], 'gAAAAenc-reasoning-blob');

      final body = await bodyOf(
        request(
          messages: [
            const ChatMessage.user('q'),
            done.message,
            const ChatMessage.toolResults([
              ToolResultPart(callId: 'call_r1', json: '{"n":0}'),
            ]),
          ],
        ),
      );
      final input = body['input'] as List;
      expect(input, [
        {'role': 'user', 'content': 'q'},
        ...jsonDecode(jsonEncode(state.items)) as List,
        {
          'type': 'function_call_output',
          'call_id': 'call_r1',
          'output': '{"n":0}',
        },
      ]);
    });

    test('다른 모델이면 reasoning 없이 function_call · message 로 다시 만든다', () async {
      final done = await completedOf('stream_reasoning_tool.sse');
      final body = await bodyOf(
        request(model: 'gpt-6', messages: [done.message]),
      );
      expect(body['input'], [
        {
          'type': 'message',
          'role': 'assistant',
          'content': [
            {'type': 'output_text', 'text': '찾아볼게요'},
          ],
        },
        {
          'type': 'function_call',
          'call_id': 'call_r1',
          'name': 'search_diary',
          'arguments': '{"query":"강아지"}',
        },
      ]);
      expect(jsonEncode(body['input']), isNot(contains('encrypted_content')));
    });

    test('상태가 없거나 다른 벤더 상태면 parts 로 다시 만든다', () async {
      for (final state in <VendorTurnState?>[
        null,
        _OtherState(),
        const AnthropicTurnState(model: _model, content: []),
      ]) {
        final body = await bodyOf(
          request(
            messages: [
              ChatMessage.assistant(
                parts: const [AssistantPart.text('a')],
                vendorState: state,
              ),
            ],
          ),
        );
        expect(body['input'], [
          {
            'type': 'message',
            'role': 'assistant',
            'content': [
              {'type': 'output_text', 'text': 'a'},
            ],
          },
        ], reason: '$state');
      }
    });
  });

  group('도구 결과', () {
    test('함수 결과는 function_call_output, 사진은 뒤따르는 user input_image', () async {
      final body = await bodyOf(
        request(
          messages: [
            ChatMessage.toolResults([
              ToolResultPart(callId: 'c1', json: '{"a":1}', images: [_image]),
              const ToolResultPart(
                callId: 'c2',
                json: '{"b":2}',
                isError: true,
              ),
            ]),
          ],
        ),
      );
      final url = 'data:image/jpeg;base64,${base64Encode([1, 2, 3])}';
      expect(body['input'], [
        {'type': 'function_call_output', 'call_id': 'c1', 'output': '{"a":1}'},
        {'type': 'function_call_output', 'call_id': 'c2', 'output': '{"b":2}'},
        {
          'role': 'user',
          'content': [
            {'type': 'input_text', 'text': '(도구 결과 사진)'},
            {'type': 'input_image', 'image_url': url},
          ],
        },
      ]);
    });

    test('사진이 없으면 뒤따르는 user 입력도 없다', () async {
      final body = await bodyOf(
        request(
          messages: [
            const ChatMessage.toolResults([
              ToolResultPart(callId: 'c1', json: '{}'),
            ]),
          ],
        ),
      );
      expect(body['input'], [
        {'type': 'function_call_output', 'call_id': 'c1', 'output': '{}'},
      ]);
    });

    test('imagesInToolOutput 이면 output 배열에 input_image', () async {
      final body = await bodyOf(
        request(
          messages: [
            ChatMessage.toolResults([
              ToolResultPart(callId: 'c1', json: '{"a":1}', images: [_image]),
              const ToolResultPart(callId: 'c2', json: '{"b":2}'),
            ]),
          ],
        ),
        make: (c) => OpenAiChatModel.withTimeouts(
          c,
          const NoopChatTrace(),
          imagesInToolOutput: true,
        ),
      );
      final url = 'data:image/jpeg;base64,${base64Encode([1, 2, 3])}';
      expect(body['input'], [
        {
          'type': 'function_call_output',
          'call_id': 'c1',
          'output': [
            {'type': 'input_text', 'text': '{"a":1}'},
            {'type': 'input_image', 'image_url': url},
          ],
        },
        {'type': 'function_call_output', 'call_id': 'c2', 'output': '{"b":2}'},
      ]);
    });
  });

  group('usage', () {
    Future<TokenUsage?> usageOf(Object? usage) async {
      final events = await run(clientOf([_completed(usage: usage)]));
      return events.whereType<ModelCompleted>().single.usage;
    }

    test('usage 가 없거나 모양이 어긋나면 null', () async {
      expect(await usageOf(null), isNull);
      expect(await usageOf('x'), isNull);
      expect(await usageOf({'input_tokens': '1', 'output_tokens': 2}), isNull);
      expect(await usageOf({'input_tokens': 1}), isNull);
      expect(
        await usageOf({
          'input_tokens': 1,
          'output_tokens': 2,
          'input_tokens_details': {'cached_tokens': 'x'},
        }),
        isNull,
      );
    });

    test('세부 항목이 없으면 cacheRead 0 · reasoning null', () async {
      expect(
        await usageOf({'input_tokens': 1, 'output_tokens': 2}),
        const TokenUsage(inputTokens: 1, outputTokens: 2),
      );
    });
  });

  group('오류', () {
    Future<ChatModelException> errorOf(int status, String body) async {
      try {
        await run(clientOf([body], status: status));
      } on ChatModelException catch (e) {
        return e;
      }
      fail('no exception');
    }

    Future<ChatModelErrorKind> kindOf(int status, String fixture) async =>
        (await errorOf(status, chatFixture('openai/$fixture'))).kind;

    test('429 insufficient_quota → quotaExceeded', () async {
      expect(
        await kindOf(429, 'error_insufficient_quota.json'),
        ChatModelErrorKind.quotaExceeded,
      );
    });

    test('429 rate_limit_exceeded → rateLimited', () async {
      expect(
        await kindOf(429, 'error_rate_limit.json'),
        ChatModelErrorKind.rateLimited,
      );
      expect((await errorOf(429, '')).kind, ChatModelErrorKind.rateLimited);
    });

    test('401 → invalidKey(본문 없이도)', () async {
      expect(
        await kindOf(401, 'error_invalid_key.json'),
        ChatModelErrorKind.invalidKey,
      );
      expect((await errorOf(401, '')).kind, ChatModelErrorKind.invalidKey);
      expect((await errorOf(403, '')).kind, ChatModelErrorKind.invalidKey);
    });

    test('404 model_not_found → modelUnavailable', () async {
      expect(
        await kindOf(404, 'error_model_not_found.json'),
        ChatModelErrorKind.modelUnavailable,
      );
      expect(
        await kindOf(400, 'error_model_not_found.json'),
        ChatModelErrorKind.modelUnavailable,
      );
      expect(
        (await errorOf(404, '')).kind,
        ChatModelErrorKind.modelUnavailable,
      );
    });

    test('이미지 코드 → imagesUnsupported', () async {
      final code =
          (jsonDecode(chatFixture('openai/error_image.json'))
              as Map)['error']['code'];
      expect(OpenAiChatModel.imageUnsupportedCodes, contains(code));
      expect(
        await kindOf(400, 'error_image.json'),
        ChatModelErrorKind.imagesUnsupported,
      );
    });

    test('503 → overloaded, 그 밖은 server', () async {
      expect((await errorOf(503, '')).kind, ChatModelErrorKind.overloaded);
      expect((await errorOf(500, '')).kind, ChatModelErrorKind.server);
      expect(
        (await errorOf(
          400,
          jsonEncode({
            'error': {'type': 'invalid_request_error', 'code': null},
          }),
        )).kind,
        ChatModelErrorKind.server,
      );
    });

    test('오류 본문의 message 는 예외에 없다', () async {
      final e = await errorOf(
        401,
        chatFixture('openai/error_invalid_key.json'),
      );
      expect(e.toString(), isNot(contains('sk-proj')));
      expect(e.toString(), isNot(contains('Incorrect')));
    });

    test('오류 본문이 16KB 를 넘으면 상태 코드로 판정한다', () async {
      final big = jsonEncode({
        'error': {'code': 'insufficient_quota', 'message': 'x' * (17 * 1024)},
      });
      expect((await errorOf(429, big)).kind, ChatModelErrorKind.rateLimited);
    });

    test('스트림 중 response.failed → 매핑된 예외', () async {
      Future<ChatModelErrorKind> failedKind(Object? error) async {
        try {
          await run(
            clientOf([
              sse('response.created', {
                'response': {'status': 'in_progress', 'output': []},
              }),
              sse('response.failed', {
                'type': 'response.failed',
                'response': {'status': 'failed', 'error': error, 'output': []},
              }),
            ]),
          );
        } on ChatModelException catch (e) {
          return e.kind;
        }
        fail('no exception');
      }

      expect(
        await failedKind({'code': 'rate_limit_exceeded', 'message': 'm'}),
        ChatModelErrorKind.rateLimited,
      );
      expect(
        await failedKind({'code': 'server_error', 'message': 'm'}),
        ChatModelErrorKind.server,
      );
      expect(await failedKind(null), ChatModelErrorKind.server);
    });

    test('스트림 중 error 이벤트 → 매핑된 예외(code 가 최상위여도 · error 안이어도)', () async {
      Future<ChatModelErrorKind> kindFor(Map<String, Object?> data) async {
        try {
          await run(clientOf([sse('error', data)]));
        } on ChatModelException catch (e) {
          return e.kind;
        }
        fail('no exception');
      }

      expect(
        await kindFor({
          'type': 'error',
          'code': 'insufficient_quota',
          'message': 'm',
        }),
        ChatModelErrorKind.quotaExceeded,
      );
      expect(
        await kindFor({
          'type': 'error',
          'error': {'type': 'invalid_request_error', 'code': 'model_not_found'},
        }),
        ChatModelErrorKind.modelUnavailable,
      );
    });

    test('완료 이벤트 없이 스트림이 끝나면 network', () async {
      expect(
        () => run(
          clientOf([
            sse('response.output_text.delta', {'delta': 'a'}),
          ]),
        ),
        throwsA(
          isA<ChatModelException>().having(
            (e) => e.kind,
            'kind',
            ChatModelErrorKind.network,
          ),
        ),
      );
    });

    test('data 가 JSON 이 아니거나 모양이 어긋나면 server', () async {
      for (final chunk in [
        'event: response.completed\ndata: nope\n\n',
        sse('response.completed', {'response': 'x'}),
        sse('response.completed', {
          'response': {
            'status': 'completed',
            'output': [
              {
                'type': 'function_call',
                'call_id': 'c',
                'name': 'n',
                'arguments': '{',
              },
            ],
          },
        }),
      ]) {
        expect(
          () => run(clientOf([chunk])),
          throwsA(
            isA<ChatModelException>().having(
              (e) => e.kind,
              'kind',
              ChatModelErrorKind.server,
            ),
          ),
          reason: chunk,
        );
      }
    });

    test('요청 단계 SocketException 은 network', () async {
      final client = MockClient.streaming(
        (r, b) async => throw const SocketException('down'),
      );
      expect(
        () => run(client),
        throwsA(
          isA<ChatModelException>().having(
            (e) => e.kind,
            'kind',
            ChatModelErrorKind.network,
          ),
        ),
      );
    });
  });

  test('toString 에 키 없음(ModelRequest · OpenAiTurnState)', () async {
    expect(
      request(apiKey: 'sk-proj-secret').toString(),
      isNot(contains('secret')),
    );
    final done = await completedOf('stream_reasoning_tool.sse');
    final text = done.message.vendorState.toString();
    expect(text, 'OpenAiTurnState(items: 3)');
    expect(text, isNot(contains('enc')));
  });

  test('픽스처는 손으로 만든 것으로 적혀 있다', () {
    for (final name in [
      'stream_text.sse',
      'stream_tool_call.sse',
      'stream_reasoning_tool.sse',
      'stream_refusal.sse',
      'stream_incomplete.sse',
    ]) {
      expect(
        chatFixture('openai/$name').split('\n').first,
        ': hand-made — re-record (O7)',
        reason: name,
      );
    }
    for (final name in [
      'error_insufficient_quota.json',
      'error_rate_limit.json',
      'error_invalid_key.json',
      'error_model_not_found.json',
      'error_image.json',
    ]) {
      expect(handMadeFixtures['openai/$name'], 'O6', reason: name);
    }
    expect(handMadeFixtures['openai/models.json'], isNotNull);
  });

  group('trace', () {
    test('req · head · first · block · textDelta · msgStop 을 찍는다', () async {
      final trace = RecordingChatTrace();
      await modelOf(
        fixtureClient('stream_reasoning_tool.sse'),
        trace: trace,
      ).stream(request(fastMode: true)).toList();
      expect(trace.labels, [
        ChatTraceMark.req,
        ChatTraceMark.head,
        ChatTraceMark.first,
        ChatTraceMark.blockStart,
        ChatTraceMark.blockStop,
        ChatTraceMark.blockStart,
        ChatTraceMark.textDelta,
        ChatTraceMark.blockStop,
        ChatTraceMark.blockStart,
        ChatTraceMark.blockStop,
        ChatTraceMark.msgStop,
      ]);
      expect(trace.dataOf(ChatTraceMark.req).single, {
        'vendor': 'openai',
        'model': _model,
        'fast': true,
      });
      expect(
        [for (final d in trace.dataOf(ChatTraceMark.blockStart)) d['kind']],
        ['thinking', 'text', 'tool_use'],
      );
      expect(
        trace.dataOf(ChatTraceMark.blockStart).last['tool'],
        'search_diary',
      );
      expect(trace.dataOf(ChatTraceMark.msgStop).single, {
        'stop': 'toolUse',
        'in': 1500,
        'out': 210,
        'cacheRead': 1024,
        'cacheWrite': 0,
        'reasoning': 180,
      });
      final all = jsonEncode([for (final m in trace.marks) m.$2]);
      expect(all, isNot(contains('강아지')));
      expect(all, isNot(contains('찾아볼게요')));
    });

    test('output_item 이벤트가 없으면 block 표시도 없다', () async {
      final trace = RecordingChatTrace();
      await modelOf(
        clientOf([
          sse('response.output_text.delta', {'delta': 'a'}),
          _completed(),
        ]),
        trace: trace,
      ).stream(request()).toList();
      expect(trace.labels, [
        ChatTraceMark.req,
        ChatTraceMark.head,
        ChatTraceMark.first,
        ChatTraceMark.textDelta,
        ChatTraceMark.msgStop,
      ]);
    });

    test('trace 가 꺼져 있으면 mark 를 부르지 않는다', () async {
      final trace = RecordingChatTrace(enabled: false);
      await modelOf(
        fixtureClient('stream_text.sse'),
        trace: trace,
      ).stream(request()).toList();
      expect(trace.marks, isEmpty);
    });
  });

  group('취소', () {
    test('상태 줄을 기다리는 중 취소하면 abortTrigger 가 바로 끝난다', () async {
      final client = _HangingClient();
      final events = <Object>[];
      final trace = RecordingChatTrace();
      final sub = modelOf(
        client,
        trace: trace,
      ).stream(request()).listen(events.add, onError: events.add);
      await pumpEventQueue();
      expect(client.request, isA<http.Abortable>());

      await sub.cancel();

      expect(await _completedSoon(client.abortTrigger), isTrue);
      await pumpEventQueue();
      expect(events, isEmpty);
      expect(trace.labels, contains(ChatTraceMark.abort));
    });

    test('SSE 중 취소하면 응답 구독이 끊기고 이후 이벤트가 없다', () async {
      var bytesCancelled = false;
      final bytes = StreamController<List<int>>(
        onCancel: () => bytesCancelled = true,
      );
      addTearDown(bytes.close);
      final client = _HangingClient();
      final events = <Object>[];
      var done = false;
      final sub = modelOf(client)
          .stream(request())
          .listen(events.add, onError: events.add, onDone: () => done = true);
      await pumpEventQueue();
      client.respond(bytes.stream);
      bytes.add(utf8.encode(sse('response.output_text.delta', {'delta': 'a'})));
      await pumpEventQueue();
      expect(events, hasLength(1));

      await sub.cancel();

      expect(await _completedSoon(client.abortTrigger), isTrue);
      await pumpEventQueue();
      expect(bytesCancelled, isTrue);
      bytes.add(utf8.encode(sse('response.output_text.delta', {'delta': 'b'})));
      await pumpEventQueue();
      expect(events, hasLength(1));
      expect(done, isFalse);
    });

    test('상태 줄이 응답 대기 시간 안에 오지 않으면 요청을 끊고 network', () async {
      final client = _HangingClient();
      final future = OpenAiChatModel.withTimeouts(
        client,
        const NoopChatTrace(),
        responseTimeout: const Duration(milliseconds: 10),
      ).stream(request()).toList();
      await expectLater(
        future,
        throwsA(
          isA<ChatModelException>().having(
            (e) => e.kind,
            'kind',
            ChatModelErrorKind.network,
          ),
        ),
      );
      expect(await _completedSoon(client.abortTrigger), isTrue);
    });

    test('정상 종료면 abortTrigger 는 끝나지 않는다', () async {
      final client = _HangingClient();
      final future = modelOf(client).stream(request()).toList();
      await pumpEventQueue();
      client.respond(Stream.value(utf8.encode(_completed())));
      await future;
      expect(await _completedSoon(client.abortTrigger), isFalse);
    });

    test('기본 대기 시간은 응답 60초, SSE 유휴 90초, 목록 10초', () {
      final m = modelOf(MockClient((_) async => http.Response('', 200)));
      expect(m.responseTimeout, const Duration(seconds: 60));
      expect(m.idleTimeout, const Duration(seconds: 90));
      expect(m.listTimeout, const Duration(seconds: 10));
    });
  });

  group('listModels', () {
    MockClient listClient(
      Object body, {
      int status = 200,
      void Function(http.BaseRequest)? onRequest,
    }) => MockClient.streaming((r, b) async {
      await b.drain<void>();
      onRequest?.call(r);
      return http.StreamedResponse(
        Stream.value(utf8.encode(body is String ? body : jsonEncode(body))),
        status,
      );
    });

    test('models.json → id · createdAt(초)', () async {
      final result = await modelOf(
        listClient(chatFixture('openai/models.json')),
      ).listModels('k');
      final models = (result as ModelListOk).models;
      expect(models.map((m) => m.id), [
        'gpt-5.5',
        'gpt-5.5-2026-09-01',
        'o5-mini',
        'text-embedding-4',
        'gpt-no-created',
      ]);
      expect(
        models.first,
        ModelInfo(
          id: 'gpt-5.5',
          displayName: 'gpt-5.5',
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            1790000000 * 1000,
            isUtc: true,
          ),
        ),
      );
      expect(models.first.supportsTools, isNull);
      expect(models.first.supportsImages, isNull);
      expect(models.last.createdAt, isNull);
    });

    test('Bearer 헤더 · GET /v1/models', () async {
      late http.BaseRequest req;
      await modelOf(
        listClient({'data': []}, onRequest: (r) => req = r),
      ).listModels('sk-proj-k');
      expect(req.method, 'GET');
      expect(req.url, Uri.parse('https://api.openai.com/v1/models'));
      expect(req.headers['authorization'], 'Bearer sk-proj-k');
    });

    test('401 · 403 → invalidKey', () async {
      for (final status in [401, 403]) {
        expect(
          await modelOf(listClient('', status: status)).listModels('k'),
          const ModelListResult.invalidKey(),
          reason: '$status',
        );
      }
    });

    test('500 · 네트워크 · 시간 초과 → unreachable', () async {
      for (final status in [500, 429, 503]) {
        expect(
          await modelOf(listClient('', status: status)).listModels('k'),
          const ModelListResult.unreachable(),
          reason: '$status',
        );
      }
      final socket = MockClient.streaming(
        (r, b) async => throw const SocketException('down'),
      );
      expect(
        await modelOf(socket).listModels('k'),
        const ModelListResult.unreachable(),
      );
      final never = Completer<http.StreamedResponse>();
      final hanging = MockClient.streaming((r, b) async {
        await b.drain<void>();
        return never.future;
      });
      expect(
        await OpenAiChatModel.withTimeouts(
          hanging,
          const NoopChatTrace(),
          listTimeout: const Duration(milliseconds: 10),
        ).listModels('k'),
        const ModelListResult.unreachable(),
      );
    });

    test('200 인데 본문이 JSON 이 아니면 ok(빈 목록)', () async {
      expect(
        await modelOf(listClient('nope')).listModels('k'),
        const ModelListResult.ok([]),
      );
    });
  });

  group('잘린 응답(incomplete)', () {
    String incomplete(List<Map<String, Object?>> output) =>
        sse('response.incomplete', {
          'type': 'response.incomplete',
          'response': {
            'status': 'incomplete',
            'incomplete_details': {'reason': 'max_output_tokens'},
            'output': output,
          },
        });

    test('끝나지 않은 function_call 은 parts · items 에서 빼고 maxTokens', () async {
      final events = await run(
        clientOf([
          incomplete([
            {
              'type': 'message',
              'status': 'completed',
              'content': [
                {'type': 'output_text', 'text': '찾아볼게요'},
              ],
            },
            {
              'type': 'function_call',
              'status': 'incomplete',
              'call_id': 'c1',
              'name': 'search_diary',
              'arguments': '{"query":"강',
            },
          ]),
        ]),
      );
      final done = events.whereType<ModelCompleted>().single;
      expect(done.stop, StopKind.maxTokens);
      expect(done.message.parts, [const AssistantPart.text('찾아볼게요')]);
      final state = done.message.vendorState! as OpenAiTurnState;
      expect(state.items.map((i) => i['type']), ['message']);
    });

    test('뒤따르는 항목이 없는 끝의 reasoning 은 items 에서 뺀다', () async {
      final events = await run(
        clientOf([
          incomplete([
            {'type': 'reasoning', 'id': 'rs_1', 'encrypted_content': 'e1'},
            {
              'type': 'message',
              'status': 'incomplete',
              'content': [
                {'type': 'output_text', 'text': 'a'},
              ],
            },
            {'type': 'reasoning', 'id': 'rs_2', 'encrypted_content': 'e2'},
          ]),
        ]),
      );
      final done = events.whereType<ModelCompleted>().single;
      expect(done.stop, StopKind.maxTokens);
      final state = done.message.vendorState! as OpenAiTurnState;
      expect(state.items.map((i) => i['id']), ['rs_1', null]);
    });

    test('추론만 하다 잘리면 items 가 비고 다음 요청에 아무것도 싣지 않는다', () async {
      final events = await run(
        clientOf([
          incomplete([
            {'type': 'reasoning', 'id': 'rs_1', 'encrypted_content': 'e1'},
          ]),
        ]),
      );
      final done = events.whereType<ModelCompleted>().single;
      expect(done.stop, StopKind.maxTokens);
      expect((done.message.vendorState! as OpenAiTurnState).items, isEmpty);
      final body = await bodyOf(request(messages: [done.message]));
      expect(body['input'], isEmpty);
    });

    test('completed 응답은 끝의 reasoning 도 그대로 둔다', () async {
      final events = await run(
        clientOf([
          _completed(
            output: [
              {'type': 'reasoning', 'id': 'rs_1', 'encrypted_content': 'e1'},
            ],
          ),
        ]),
      );
      final state =
          events.whereType<ModelCompleted>().single.message.vendorState!
              as OpenAiTurnState;
      expect(state.items, hasLength(1));
    });
  });

  test('event 줄이 없는 SSE 는 payload 의 type 으로 처리한다', () async {
    String bare(Map<String, Object?> data) => 'data: ${jsonEncode(data)}\n\n';
    final events = await run(
      clientOf([
        bare({'type': 'response.output_text.delta', 'delta': 'a'}),
        bare({
          'type': 'response.completed',
          'response': {
            'status': 'completed',
            'output': [
              {
                'type': 'message',
                'content': [
                  {'type': 'output_text', 'text': 'a'},
                ],
              },
            ],
          },
        }),
      ]),
    );
    expect(events.whereType<ModelTextDelta>().single.text, 'a');
    final done = events.whereType<ModelCompleted>().single;
    expect(done.stop, StopKind.endTurn);
    expect(done.message.parts, [const AssistantPart.text('a')]);
  });

  group('진행 이벤트', () {
    test('progressNotes 는 false(노트를 아직 내지 않는다)', () {
      expect(modelOf(clientOf(const [])).progressNotes, isFalse);
    });

    test('reasoning 항목 추가에 thinking(), 함수 호출 항목 추가에 toolCallStarted, '
        '완료에 toolCallReady 를 낸다', () async {
      final events = await run(fixtureClient('stream_reasoning_tool.sse'));
      expect(events, hasLength(5));
      expect(events[0], isA<ModelThinking>());
      expect(events[1], isA<ModelTextDelta>());
      final started = events[2] as ModelToolCallStarted;
      expect((started.id, started.name), ('call_r1', 'search_diary'));
      final ready = events[3] as ModelToolCallReady;
      expect((ready.id, ready.name), ('call_r1', 'search_diary'));
      expect(ready.input, {'query': '강아지'});
      final done = events[4] as ModelCompleted;
      expect(done.message.parts.whereType<ToolCallPart>().single.id, 'call_r1');
      expect(events.whereType<ModelProgress>(), isEmpty);
    });

    test('끝나지 않았거나 인자를 못 읽는 함수 호출은 toolCallReady 를 내지 않는다', () async {
      Map<String, Object?> call(String status, String arguments) => {
        'id': 'fc',
        'type': 'function_call',
        'status': status,
        'call_id': 'c1',
        'name': 'search_diary',
        'arguments': arguments,
      };
      final events = await run(
        clientOf([
          sse('response.output_item.done', {'item': call('incomplete', '{"q')}),
          sse('response.output_item.done', {'item': call('completed', '{"q')}),
          sse('response.output_item.done', {
            'item': {'type': 'function_call', 'call_id': 1, 'name': 'x'},
          }),
          _completed(),
        ]),
      );
      expect(events.whereType<ModelToolCallReady>(), isEmpty);
      expect(events.single, isA<ModelCompleted>());
    });
  });
}
