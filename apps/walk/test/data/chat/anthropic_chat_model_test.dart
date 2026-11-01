import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:walk/data/chat/anthropic_chat_model.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_trace.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/tool/tool_result.dart';

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

ModelRequest request({
  String apiKey = 'sk-test',
  String model = 'claude-opus-5-5',
  List<ChatMessage> messages = const [],
  List<ToolSpec> tools = const [],
}) => ModelRequest(
  apiKey: apiKey,
  model: model,
  system: 'sys',
  messages: messages,
  tools: tools,
);

Future<List<ModelEvent>> run(MockClient client, [ModelRequest? r]) =>
    AnthropicChatModel(
      client,
      const NoopChatTrace(),
    ).stream(r ?? request()).toList();

/// 요청 본문을 잡는 끝난 응답 하나.
MockClient capture(void Function(Map<String, dynamic> body) onBody) =>
    clientOf([
      sse('message_start', {'type': 'message_start'}),
      sse('message_delta', {
        'delta': {'stop_reason': 'end_turn'},
      }),
      sse('message_stop', {}),
    ], onRequest: (_, b) => onBody(jsonDecode(b) as Map<String, dynamic>));

/// 다른 벤더의 상태(어댑터가 모르는 타입).
class _OtherState implements VendorTurnState {
  @override
  ChatVendor get vendor => ChatVendor.openai;
  @override
  String get model => 'gpt';
}

String _textEvents(String stop, {Map<String, Object?>? startUsage}) => [
  sse('message_start', {
    'type': 'message_start',
    'message': {'usage': ?startUsage},
  }),
  sse('content_block_start', {
    'index': 0,
    'content_block': {'type': 'text', 'text': ''},
  }),
  sse('content_block_delta', {
    'index': 0,
    'delta': {'type': 'text_delta', 'text': 'a'},
  }),
  sse('content_block_stop', {'index': 0}),
  sse('message_delta', {
    'delta': {'stop_reason': stop},
  }),
  sse('message_stop', {}),
].join();

void main() {
  test('요청에 정해진 헤더와 본문 필드를 담는다', () async {
    late http.BaseRequest req;
    late Map<String, dynamic> body;
    final client = clientOf(
      [
        sse('message_start', {'type': 'message_start'}),
        sse('message_delta', {
          'delta': {'stop_reason': 'end_turn'},
        }),
        sse('message_stop', {}),
      ],
      onRequest: (r, b) {
        req = r;
        body = jsonDecode(b) as Map<String, dynamic>;
      },
    );
    await run(
      client,
      request(
        messages: const [ChatMessage.user('hi')],
        tools: const [ToolSpec(name: 't', description: 'd', parameters: {})],
      ),
    );
    expect(req.method, 'POST');
    expect(req.url.toString(), 'https://api.anthropic.com/v1/messages');
    expect(req.headers['x-api-key'], 'sk-test');
    expect(req.headers['anthropic-version'], '2026-10-21');
    expect(req.headers['anthropic-beta'], 'server-side-fallback-2026-07-01');
    expect(req.headers['content-type'], contains('application/json'));
    expect(body['model'], 'claude-opus-5-5');
    expect(body['max_tokens'], 16000);
    expect(body['stream'], true);
    expect(body['fallbacks'], 'default');
    expect(body['output_config'], {'effort': 'low'});
    expect(body['system'], 'sys');
    expect(body['messages'], hasLength(1));
    expect(body['tools'], hasLength(1));
    for (final k in [
      'temperature',
      'top_p',
      'top_k',
      'thinking',
      'tool_choice',
    ]) {
      expect(body.containsKey(k), isFalse, reason: k);
    }
  });

  test('text_delta 를 차례로 흘리고 completed 에 전체 text 블록을 담는다', () async {
    final events = await run(
      clientOf([
        sse('message_start', {}),
        sse('content_block_start', {
          'index': 0,
          'content_block': {'type': 'text', 'text': ''},
        }),
        sse('ping', {}),
        sse('content_block_delta', {
          'index': 0,
          'delta': {'type': 'text_delta', 'text': '안녕'},
        }),
        sse('content_block_delta', {
          'index': 0,
          'delta': {'type': 'text_delta', 'text': '하세요'},
        }),
        sse('content_block_stop', {'index': 0}),
        sse('message_delta', {
          'delta': {'stop_reason': 'end_turn'},
        }),
        sse('message_stop', {}),
      ]),
    );
    expect(events.whereType<ModelTextDelta>().map((e) => e.text), [
      '안녕',
      '하세요',
    ]);
    final done = events.last as ModelCompleted;
    expect(done.stop, StopKind.endTurn);
    expect(done.message.parts, const [AssistantPart.text('안녕하세요')]);
    expect((done.message.vendorState! as AnthropicTurnState).content, [
      {'type': 'text', 'text': '안녕하세요'},
    ]);
  });

  test('바이트가 UTF-8 중간에서 잘려도 복원한다', () async {
    final all = utf8.encode(
      sse('content_block_start', {
            'index': 0,
            'content_block': {'type': 'text', 'text': ''},
          }) +
          sse('content_block_delta', {
            'index': 0,
            'delta': {'type': 'text_delta', 'text': '한글'},
          }) +
          sse('message_delta', {
            'delta': {'stop_reason': 'end_turn'},
          }) +
          sse('message_stop', {}),
    );
    final client = MockClient.streaming((r, b) async {
      await b.drain<void>();
      return http.StreamedResponse(
        Stream.fromIterable([
          for (final x in all) [x],
        ]),
        200,
      );
    });
    final events = await run(client);
    expect((events.last as ModelCompleted).message.parts, const [
      AssistantPart.text('한글'),
    ]);
  });

  test(
    'completed 는 parts(text · toolCall) 와 thinking 서명을 담은 vendorState 를 준다',
    () async {
      final events = await run(
        clientOf([
          sse('content_block_start', {
            'index': 0,
            'content_block': {'type': 'thinking', 'thinking': ''},
          }),
          sse('content_block_delta', {
            'index': 0,
            'delta': {'type': 'thinking_delta', 'thinking': '음'},
          }),
          sse('content_block_delta', {
            'index': 0,
            'delta': {'type': 'thinking_delta', 'thinking': '...'},
          }),
          sse('content_block_delta', {
            'index': 0,
            'delta': {'type': 'signature_delta', 'signature': 'SIG'},
          }),
          sse('content_block_stop', {'index': 0}),
          sse('content_block_start', {
            'index': 1,
            'content_block': {'type': 'text', 'text': ''},
          }),
          sse('content_block_delta', {
            'index': 1,
            'delta': {'type': 'text_delta', 'text': 'a'},
          }),
          sse('content_block_stop', {'index': 1}),
          sse('message_delta', {
            'delta': {'stop_reason': 'end_turn'},
          }),
          sse('message_stop', {}),
        ]),
      );
      final done = events.last as ModelCompleted;
      expect(done.message.parts, const [AssistantPart.text('a')]);
      final state = done.message.vendorState! as AnthropicTurnState;
      expect(state.vendor, ChatVendor.anthropic);
      expect(state.model, 'claude-opus-5-5');
      expect(state.content, [
        {'type': 'thinking', 'thinking': '음...', 'signature': 'SIG'},
        {'type': 'text', 'text': 'a'},
      ]);
      expect(state.toString(), isNot(contains('SIG')));
      expect(state.toString(), isNot(contains('음')));
      expect(done.message.toString(), isNot(contains('SIG')));
    },
  );

  test('조각난 input_json_delta 를 모아 tool_use.input 으로 만든다', () async {
    final events = await run(
      clientOf([
        sse('content_block_start', {
          'index': 0,
          'content_block': {
            'type': 'tool_use',
            'id': 'tu_1',
            'name': 'search',
            'input': {},
          },
        }),
        sse('content_block_delta', {
          'index': 0,
          'delta': {'type': 'input_json_delta', 'partial_json': '{"fr'},
        }),
        sse('content_block_delta', {
          'index': 0,
          'delta': {
            'type': 'input_json_delta',
            'partial_json': 'om":"2026-10-01"}',
          },
        }),
        sse('content_block_stop', {'index': 0}),
        sse('content_block_start', {
          'index': 1,
          'content_block': {
            'type': 'tool_use',
            'id': 'tu_2',
            'name': 'none',
            'input': {},
          },
        }),
        sse('content_block_stop', {'index': 1}),
        sse('message_delta', {
          'delta': {'stop_reason': 'tool_use'},
        }),
        sse('message_stop', {}),
      ]),
    );
    final done = events.last as ModelCompleted;
    expect(done.stop, StopKind.toolUse);
    expect(done.message.parts, const [
      AssistantPart.toolCall(
        id: 'tu_1',
        name: 'search',
        input: {'from': '2026-10-01'},
      ),
      AssistantPart.toolCall(id: 'tu_2', name: 'none', input: {}),
    ]);
  });

  test('401 은 invalidKey, 429 는 rateLimited, 529 는 overloaded', () async {
    Future<ChatModelErrorKind> kindFor(int status) async {
      try {
        await run(clientOf(['{"secret":"body"}'], status: status));
      } on ChatModelException catch (e) {
        expect(e.toString(), isNot(contains('secret')));
        expect(e.toString(), isNot(contains('sk-test')));
        return e.kind;
      }
      fail('no exception');
    }

    expect(await kindFor(401), ChatModelErrorKind.invalidKey);
    expect(await kindFor(403), ChatModelErrorKind.invalidKey);
    expect(await kindFor(429), ChatModelErrorKind.rateLimited);
    expect(await kindFor(529), ChatModelErrorKind.overloaded);
    expect(await kindFor(500), ChatModelErrorKind.server);
    expect(await kindFor(400), ChatModelErrorKind.server);
  });

  test('SSE error 이벤트를 매핑한다', () async {
    Future<ChatModelErrorKind> kindFor(String type) async {
      try {
        await run(
          clientOf([
            sse('error', {
              'type': 'error',
              'error': {'type': type, 'message': 'm'},
            }),
          ]),
        );
      } on ChatModelException catch (e) {
        return e.kind;
      }
      fail('no exception');
    }

    expect(await kindFor('overloaded_error'), ChatModelErrorKind.overloaded);
    expect(await kindFor('api_error'), ChatModelErrorKind.server);
  });

  test('본문 중간에 연결이 끊기면 network', () async {
    final controller = StreamController<List<int>>();
    final client = MockClient.streaming((r, b) async {
      await b.drain<void>();
      return http.StreamedResponse(controller.stream, 200);
    });
    final future = run(client);
    controller.add(
      utf8.encode(
        sse('content_block_start', {
          'index': 0,
          'content_block': {'type': 'text', 'text': ''},
        }),
      ),
    );
    controller.addError(http.ClientException('x'));
    await controller.close();
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
  });

  test('message_stop 없이 스트림이 끝나면 network 이고 completed 는 없다', () async {
    final events = <ModelEvent>[];
    final stream = AnthropicChatModel(
      clientOf([
        sse('content_block_start', {
          'index': 0,
          'content_block': {'type': 'text', 'text': ''},
        }),
        sse('content_block_delta', {
          'index': 0,
          'delta': {'type': 'text_delta', 'text': 'a'},
        }),
      ]),
      const NoopChatTrace(),
    ).stream(request(apiKey: 'k'));
    await expectLater(
      stream.forEach(events.add),
      throwsA(
        isA<ChatModelException>().having(
          (e) => e.kind,
          'kind',
          ChatModelErrorKind.network,
        ),
      ),
    );
    expect(events.whereType<ModelCompleted>(), isEmpty);
    expect(events.whereType<ModelTextDelta>(), hasLength(1));
  });

  test('요청 단계 ClientException 도 network', () async {
    final client = MockClient.streaming((r, b) async {
      throw http.ClientException('down');
    });
    await expectLater(
      run(client),
      throwsA(
        isA<ChatModelException>().having(
          (e) => e.kind,
          'kind',
          ChatModelErrorKind.network,
        ),
      ),
    );
  });

  final isNetwork = throwsA(
    isA<ChatModelException>().having(
      (e) => e.kind,
      'kind',
      ChatModelErrorKind.network,
    ),
  );

  test('응답이 응답 대기 시간 안에 오지 않으면 network', () async {
    final never = Completer<http.StreamedResponse>();
    final client = MockClient.streaming((r, b) async {
      await b.drain<void>();
      return never.future;
    });
    await expectLater(
      AnthropicChatModel.withTimeouts(
        client,
        const NoopChatTrace(),
        responseTimeout: const Duration(milliseconds: 20),
      ).stream(request(apiKey: 'k')).toList(),
      isNetwork,
    );
  });

  test('SSE 줄 사이가 유휴 시간을 넘기면 network', () async {
    final controller = StreamController<List<int>>();
    final client = MockClient.streaming((r, b) async {
      await b.drain<void>();
      return http.StreamedResponse(controller.stream, 200);
    });
    controller.add(
      utf8.encode(sse('message_start', {'type': 'message_start'})),
    );
    await expectLater(
      AnthropicChatModel.withTimeouts(
        client,
        const NoopChatTrace(),
        idleTimeout: const Duration(milliseconds: 20),
      ).stream(request(apiKey: 'k')).toList(),
      isNetwork,
    );
    await controller.close();
  });

  test('기본 대기 시간은 응답 60초, SSE 유휴 90초', () {
    final model = AnthropicChatModel(
      MockClient((_) async => http.Response('', 200)),
      const NoopChatTrace(),
    );
    expect(model.responseTimeout, const Duration(seconds: 60));
    expect(model.idleTimeout, const Duration(seconds: 90));
  });

  test('이벤트 모양이 어긋나면(index 가 문자열) server', () async {
    await expectLater(
      run(
        clientOf([
          sse('content_block_start', {
            'index': 0,
            'content_block': {'type': 'text', 'text': ''},
          }),
          sse('content_block_delta', {
            'index': '0',
            'delta': {'type': 'text_delta', 'text': 'a'},
          }),
          sse('message_stop', {}),
        ]),
      ),
      throwsA(
        isA<ChatModelException>().having(
          (e) => e.kind,
          'kind',
          ChatModelErrorKind.server,
        ),
      ),
    );
  });

  test('data 가 객체가 아니면 server', () async {
    await expectLater(
      run(clientOf(['event: content_block_delta\ndata: [1,2]\n\n'])),
      throwsA(
        isA<ChatModelException>().having(
          (e) => e.kind,
          'kind',
          ChatModelErrorKind.server,
        ),
      ),
    );
  });

  test('vendor 는 anthropic', () {
    final model = AnthropicChatModel(
      MockClient((_) async => http.Response('', 200)),
      const NoopChatTrace(),
    );
    expect(model.vendor, ChatVendor.anthropic);
  });

  test('요청 본문이 전환 전과 같다', () async {
    late Map<String, dynamic> body;
    final thinking = <String, Object?>{
      'type': 'thinking',
      'thinking': '생각',
      'signature': 'sig==',
    };
    final toolUse = <String, Object?>{
      'type': 'tool_use',
      'id': 'tu_1',
      'name': 'view_entry_photos',
      'input': {'entry_id': 'e1'},
    };
    await run(
      capture((b) => body = b),
      request(
        model: 'claude-opus-5-5',
        messages: [
          const ChatMessage.user('사진 보여줘'),
          ChatMessage.assistant(
            parts: const [
              AssistantPart.text('볼게요'),
              AssistantPart.toolCall(
                id: 'tu_1',
                name: 'view_entry_photos',
                input: {'entry_id': 'e1'},
              ),
            ],
            vendorState: AnthropicTurnState(
              model: 'claude-opus-5-5',
              content: [
                thinking,
                {'type': 'text', 'text': '볼게요'},
                toolUse,
              ],
            ),
          ),
          ChatMessage.toolResults([
            ToolResultPart(
              callId: 'tu_1',
              json: '{"photos":1}',
              images: [
                ToolImage(
                  mediaType: 'image/jpeg',
                  bytes: Uint8List.fromList([1, 2, 3]),
                ),
              ],
            ),
            const ToolResultPart(
              callId: 'tu_2',
              json: '{"error":"x"}',
              isError: true,
            ),
          ]),
        ],
        tools: const [
          ToolSpec(
            name: 'view_entry_photos',
            description: '사진을 본다.',
            parameters: {
              'type': 'object',
              'properties': {
                'entry_id': {'type': 'string', 'description': '일기 id'},
              },
              'required': ['entry_id'],
            },
          ),
        ],
      ),
    );

    expect(body['model'], 'claude-opus-5-5');
    expect(body['messages'], [
      {'role': 'user', 'content': '사진 보여줘'},
      {
        'role': 'assistant',
        'content': [
          {'type': 'thinking', 'thinking': '생각', 'signature': 'sig=='},
          {'type': 'text', 'text': '볼게요'},
          {
            'type': 'tool_use',
            'id': 'tu_1',
            'name': 'view_entry_photos',
            'input': {'entry_id': 'e1'},
          },
        ],
      },
      {
        'role': 'user',
        'content': [
          {
            'type': 'tool_result',
            'tool_use_id': 'tu_1',
            'is_error': false,
            'content': [
              {'type': 'text', 'text': '{"photos":1}'},
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': 'image/jpeg',
                  'data': 'AQID',
                },
              },
            ],
          },
          {
            'type': 'tool_result',
            'tool_use_id': 'tu_2',
            'is_error': true,
            'content': [
              {'type': 'text', 'text': '{"error":"x"}'},
            ],
          },
        ],
      },
    ]);
    expect(body['tools'], [
      {
        'name': 'view_entry_photos',
        'description': '사진을 본다.',
        'input_schema': {
          'type': 'object',
          'properties': {
            'entry_id': {'type': 'string', 'description': '일기 id'},
          },
          'required': ['entry_id'],
        },
      },
    ]);
  });

  test('요청 model 은 request.model 을 쓴다', () async {
    late Map<String, dynamic> body;
    await run(capture((b) => body = b), request(model: 'other-model'));
    expect(body['model'], 'other-model');
  });

  test('vendorState 가 없는 assistant 턴은 text · tool_use 블록만으로 다시 만든다', () async {
    for (final VendorTurnState? state in [null, _OtherState()]) {
      late Map<String, dynamic> body;
      await run(
        capture((b) => body = b),
        request(
          messages: [
            const ChatMessage.user('q'),
            ChatMessage.assistant(
              parts: const [
                AssistantPart.text('찾아볼게요'),
                AssistantPart.toolCall(
                  id: 'tu_1',
                  name: 'daily_steps',
                  input: {'from': '2026-10-01', 'to': '2026-10-02'},
                ),
              ],
              vendorState: state,
            ),
          ],
        ),
      );
      expect((body['messages'] as List)[1], {
        'role': 'assistant',
        'content': [
          {'type': 'text', 'text': '찾아볼게요'},
          {
            'type': 'tool_use',
            'id': 'tu_1',
            'name': 'daily_steps',
            'input': {'from': '2026-10-01', 'to': '2026-10-02'},
          },
        ],
      }, reason: '$state');
    }
  });

  test('stop_reason 을 StopKind 로 바꾼다', () async {
    Future<StopKind> stopFor(String? reason) async {
      final events = await run(
        clientOf([
          sse('content_block_start', {
            'index': 0,
            'content_block': {'type': 'text', 'text': ''},
          }),
          sse('content_block_stop', {'index': 0}),
          sse('message_delta', {
            'delta': {'stop_reason': ?reason},
          }),
          sse('message_stop', {}),
        ]),
      );
      return (events.last as ModelCompleted).stop;
    }

    expect(await stopFor('end_turn'), StopKind.endTurn);
    expect(await stopFor(null), StopKind.endTurn);
    expect(await stopFor('tool_use'), StopKind.toolUse);
    expect(await stopFor('refusal'), StopKind.refusal);
    expect(await stopFor('max_tokens'), StopKind.maxTokens);
    expect(await stopFor('pause_turn'), StopKind.other);
  });

  test('usage 를 message_start 와 message_delta 에서 읽는다', () async {
    final events = await run(
      clientOf([
        sse('message_start', {
          'type': 'message_start',
          'message': {
            'usage': {
              'input_tokens': 2310,
              'cache_creation_input_tokens': 0,
              'cache_read_input_tokens': 2100,
              'output_tokens': 1,
            },
          },
        }),
        sse('content_block_start', {
          'index': 0,
          'content_block': {'type': 'text', 'text': ''},
        }),
        sse('content_block_stop', {'index': 0}),
        sse('message_delta', {
          'delta': {'stop_reason': 'end_turn'},
          'usage': {'output_tokens': 90},
        }),
        sse('message_delta', {
          'delta': <String, Object?>{},
          'usage': {'output_tokens': 180},
        }),
        sse('message_stop', {}),
      ]),
    );
    final done = events.last as ModelCompleted;
    expect(
      done.usage,
      const TokenUsage(
        inputTokens: 2310,
        outputTokens: 180,
        cacheReadTokens: 2100,
        cacheWriteTokens: 0,
      ),
    );
    expect(done.usage!.reasoningTokens, isNull);
    expect(done.stop, StopKind.endTurn);
  });

  test('message_delta 에 usage 가 없으면 output 은 message_start 의 값', () async {
    final events = await run(
      clientOf([
        _textEvents(
          'end_turn',
          startUsage: {'input_tokens': 10, 'output_tokens': 3},
        ),
      ]),
    );
    expect(
      (events.last as ModelCompleted).usage,
      const TokenUsage(inputTokens: 10, outputTokens: 3),
    );
  });

  test('usage 가 없거나 모양이 어긋나면 null 이고 답은 끝난다', () async {
    for (final startUsage in <Map<String, Object?>?>[
      null,
      {'input_tokens': '2310', 'output_tokens': 1},
      {'input_tokens': 2310},
      {
        'input_tokens': 2310,
        'output_tokens': 1,
        'cache_read_input_tokens': 'x',
      },
    ]) {
      final events = await run(
        clientOf([_textEvents('end_turn', startUsage: startUsage)]),
      );
      final done = events.last as ModelCompleted;
      expect(done.usage, isNull, reason: '$startUsage');
      expect(done.message.parts, const [AssistantPart.text('a')]);
    }
  });

  test('요청 본문에 서버 저장 관련 필드가 없다', () async {
    late Map<String, dynamic> body;
    await run(capture((b) => body = b));
    expect(body.containsKey('store'), isFalse);
    expect(body.containsKey('metadata'), isFalse);
  });

  group('trace', () {
    List<String> toolRound() => [
      sse('message_start', {
        'type': 'message_start',
        'message': {
          'usage': {
            'input_tokens': 2310,
            'output_tokens': 1,
            'cache_read_input_tokens': 7,
            'cache_creation_input_tokens': 3,
          },
        },
      }),
      sse('content_block_start', {
        'index': 0,
        'content_block': {'type': 'thinking', 'thinking': ''},
      }),
      sse('content_block_delta', {
        'index': 0,
        'delta': {'type': 'thinking_delta', 'thinking': '비밀 생각'},
      }),
      sse('content_block_stop', {'index': 0}),
      sse('content_block_start', {
        'index': 1,
        'content_block': {'type': 'text', 'text': ''},
      }),
      sse('content_block_delta', {
        'index': 1,
        'delta': {'type': 'text_delta', 'text': '찾아볼게요'},
      }),
      sse('content_block_stop', {'index': 1}),
      sse('content_block_start', {
        'index': 2,
        'content_block': {
          'type': 'tool_use',
          'id': 'tu1',
          'name': 'search_diary',
          'input': {},
        },
      }),
      sse('content_block_delta', {
        'index': 2,
        'delta': {
          'type': 'input_json_delta',
          'partial_json': '{"query":"비밀 검색어"}',
        },
      }),
      sse('content_block_stop', {'index': 2}),
      sse('message_delta', {
        'delta': {'stop_reason': 'tool_use'},
        'usage': {'output_tokens': 180},
      }),
      sse('message_stop', {}),
    ];

    test(
      'trace 가 켜져 있으면 req · head · first · block · textDelta · msgStop 을 차례로 찍는다',
      () async {
        final trace = RecordingChatTrace();
        await AnthropicChatModel(
          clientOf(toolRound()),
          trace,
        ).stream(request(apiKey: 'sk-ant-secret')).toList();

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
          'vendor': 'anthropic',
          'model': 'claude-opus-5-5',
          'fast': false,
        });
        expect(trace.dataOf(ChatTraceMark.blockStart), [
          {'kind': 'thinking'},
          {'kind': 'text'},
          {'kind': 'tool_use', 'tool': 'search_diary'},
        ]);
        expect(trace.dataOf(ChatTraceMark.textDelta).single, {'chars': 5});
        expect(trace.dataOf(ChatTraceMark.msgStop).single, {
          'stop': 'toolUse',
          'in': 2310,
          'out': 180,
          'cacheRead': 7,
          'cacheWrite': 3,
        });
        final all = trace.marks.map((m) => '${m.$2}').join();
        expect(all, isNot(contains('비밀')));
        expect(all, isNot(contains('sk-')));
      },
    );

    test('오류 상태면 req · head 까지만 찍는다', () async {
      final trace = RecordingChatTrace();
      await expectLater(
        AnthropicChatModel(
          clientOf(const [], status: 401),
          trace,
        ).stream(request()).toList(),
        throwsA(isA<ChatModelException>()),
      );
      expect(trace.labels, [ChatTraceMark.req, ChatTraceMark.head]);
    });

    test('trace 가 꺼져 있으면 mark 를 부르지 않는다', () async {
      final trace = RecordingChatTrace(enabled: false);
      await AnthropicChatModel(
        clientOf(toolRound()),
        trace,
      ).stream(request()).toList();
      expect(trace.marks, isEmpty);
    });
  });
}
