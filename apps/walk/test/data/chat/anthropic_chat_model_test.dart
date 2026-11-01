import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:walk/data/chat/anthropic_chat_model.dart';
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

ModelRequest request({
  String apiKey = 'sk-test',
  String model = 'claude-opus-5-5',
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

  test('요청 model 은 ModelRequest.model 이다', () async {
    late Map<String, dynamic> body;
    await run(capture((b) => body = b), request(model: 'claude-sonnet-9-9'));
    expect(body['model'], 'claude-sonnet-9-9');
  });

  group('모델별 필드', () {
    /// 요청 하나를 보내고 (헤더, 본문) 을 돌려준다.
    Future<(Map<String, String>, Map<String, dynamic>)> sent(
      ModelRequest r, {
      Map<ChatVendor, List<FastModeSpec>> specs = fastModeSpecs,
    }) async {
      late http.BaseRequest req;
      late Map<String, dynamic> body;
      final client = clientOf(
        [
          sse('message_start', {'type': 'message_start'}),
          sse('message_stop', {}),
        ],
        onRequest: (q, b) {
          req = q;
          body = jsonDecode(b) as Map<String, dynamic>;
        },
      );
      await AnthropicChatModel.withTimeouts(
        client,
        const NoopChatTrace(),
        fastSpecs: specs,
      ).stream(r).toList();
      return (req.headers, body);
    }

    test('effort 는 supportsEffortOf 가 참일 때만 싣는다', () async {
      const supported = 'claude-sonnet-9-9';
      const unsupported = 'claude-3-haiku-x';
      expect(supportsEffortOf(ChatVendor.anthropic, supported), isTrue);
      expect(supportsEffortOf(ChatVendor.anthropic, unsupported), isFalse);

      final (_, yes) = await sent(request(model: supported));
      expect(yes['output_config'], {'effort': 'low'});

      final (_, no) = await sent(request(model: unsupported));
      expect(no.containsKey('output_config'), isFalse);
      expect(no['model'], unsupported);
    });

    test('fastMode 면 fastModeFields 를 싣고 아니면 싣지 않는다', () async {
      const id = 'claude-sonnet-9-9';
      final specs = {
        ChatVendor.anthropic: [
          FastModeSpec(pattern: RegExp('^claude-sonnet-'), priceFactor: 2),
        ],
        ChatVendor.openai: const <FastModeSpec>[],
      };
      final (offHeaders, off) = await sent(request(model: id), specs: specs);
      final (onHeaders, on) = await sent(
        request(model: id, fastMode: true),
        specs: specs,
      );

      for (final MapEntry(:key, :value)
          in AnthropicChatModel.fastModeFields.entries) {
        expect(on[key], value, reason: key);
        expect(off.containsKey(key), isFalse, reason: key);
      }
      expect(on, {...off, ...AnthropicChatModel.fastModeFields});
      expect(
        onHeaders['anthropic-beta'],
        [
          'server-side-fallback-2026-07-01',
          ?AnthropicChatModel.fastModeBeta,
        ].join(','),
      );
      expect(offHeaders['anthropic-beta'], 'server-side-fallback-2026-07-01');
    });

    test('지원 표가 비어 있으면 fastMode 여도 본문 · 헤더가 꺼졌을 때와 같다', () async {
      const id = 'claude-sonnet-9-9';
      expect(fastModeOf(ChatVendor.anthropic, id), isNull);
      final (offHeaders, off) = await sent(request(model: id));
      final (onHeaders, on) = await sent(request(model: id, fastMode: true));
      expect(on, off);
      expect(onHeaders, offHeaders);
    });

    test('fastMode 여도 지원하지 않는 모델이면 싣지 않는다', () async {
      final specs = {
        ChatVendor.anthropic: [
          FastModeSpec(pattern: RegExp('^claude-opus-'), priceFactor: 2),
        ],
        ChatVendor.openai: const <FastModeSpec>[],
      };
      const id = 'claude-sonnet-9-9';
      final (offHeaders, off) = await sent(request(model: id), specs: specs);
      final (onHeaders, on) = await sent(
        request(model: id, fastMode: true),
        specs: specs,
      );
      expect(on, off);
      expect(onHeaders, offHeaders);
    });
  });

  test(
    '다른 모델의 AnthropicTurnState 는 thinking 없이 text · tool_use 로 다시 만든다',
    () async {
      late Map<String, dynamic> body;
      await run(
        capture((b) => body = b),
        request(
          model: 'claude-sonnet-9-9',
          messages: [
            const ChatMessage.user('q'),
            ChatMessage.assistant(
              parts: const [
                AssistantPart.text('찾아볼게요'),
                AssistantPart.toolCall(
                  id: 'tu_1',
                  name: 'daily_steps',
                  input: {'from': '2026-10-01'},
                ),
              ],
              vendorState: AnthropicTurnState(
                model: 'claude-opus-9-9',
                content: [
                  {'type': 'thinking', 'thinking': '생각', 'signature': 'sig=='},
                  {'type': 'text', 'text': '찾아볼게요'},
                  {
                    'type': 'tool_use',
                    'id': 'tu_1',
                    'name': 'daily_steps',
                    'input': {'from': '2026-10-01'},
                  },
                ],
              ),
            ),
            const ChatMessage.toolResults([
              ToolResultPart(callId: 'tu_1', json: '{"steps":1}'),
            ]),
          ],
        ),
      );
      final messages = body['messages'] as List;
      expect(messages[1], {
        'role': 'assistant',
        'content': [
          {'type': 'text', 'text': '찾아볼게요'},
          {
            'type': 'tool_use',
            'id': 'tu_1',
            'name': 'daily_steps',
            'input': {'from': '2026-10-01'},
          },
        ],
      });
      expect(messages[2], {
        'role': 'user',
        'content': [
          {
            'type': 'tool_result',
            'tool_use_id': 'tu_1',
            'is_error': false,
            'content': [
              {'type': 'text', 'text': '{"steps":1}'},
            ],
          },
        ],
      });
      expect(jsonEncode(body), isNot(contains('sig==')));
    },
  );

  test('같은 모델이면 원본 블록 그대로', () async {
    late Map<String, dynamic> body;
    final content = <Map<String, Object?>>[
      {'type': 'thinking', 'thinking': '생각', 'signature': 'sig=='},
      {'type': 'text', 'text': '네'},
    ];
    await run(
      capture((b) => body = b),
      request(
        model: 'claude-sonnet-9-9',
        messages: [
          const ChatMessage.user('q'),
          ChatMessage.assistant(
            parts: const [AssistantPart.text('네')],
            vendorState: AnthropicTurnState(
              model: 'claude-sonnet-9-9',
              content: content,
            ),
          ),
        ],
      ),
    );
    expect((body['messages'] as List)[1], {
      'role': 'assistant',
      'content': content,
    });
  });

  test('vendorState.model 은 message_start 의 실제 모델이다(대체 모델이 답해도)', () async {
    final events = await run(
      clientOf([
        sse('message_start', {
          'type': 'message_start',
          'message': {'model': 'claude-sonnet-9-8'},
        }),
        sse('message_stop', {}),
      ]),
      request(model: 'claude-opus-9-9'),
    );
    final state =
        (events.last as ModelCompleted).message.vendorState!
            as AnthropicTurnState;
    expect(state.model, 'claude-sonnet-9-8');
  });

  test('message_start 에 모델이 없으면 vendorState.model 은 요청한 모델', () async {
    final events = await run(
      clientOf([
        sse('message_start', {
          'type': 'message_start',
          'message': {'model': 7},
        }),
        sse('message_stop', {}),
      ]),
      request(model: 'claude-opus-9-9'),
    );
    final state =
        (events.last as ModelCompleted).message.vendorState!
            as AnthropicTurnState;
    expect(state.model, 'claude-opus-9-9');
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

  group('취소', () {
    test('상태 줄을 기다리는 중에 취소하면 abortTrigger 가 바로 끝난다', () async {
      final client = _HangingClient();
      final events = <Object>[];
      final sub = AnthropicChatModel(
        client,
        const NoopChatTrace(),
      ).stream(request()).listen(events.add, onError: events.add);
      await pumpEventQueue();
      expect(client.request, isA<http.Abortable>());

      await sub.cancel();

      expect(await _completedSoon(client.abortTrigger), isTrue);
      await pumpEventQueue();
      expect(events, isEmpty);
    });

    test('SSE 를 받는 중에 취소하면 abortTrigger 가 끝나고 응답 바이트 구독이 끊긴다', () async {
      var bytesCancelled = false;
      final bytes = StreamController<List<int>>(
        onCancel: () => bytesCancelled = true,
      );
      addTearDown(bytes.close);
      final client = _HangingClient();
      final events = <Object>[];
      final sub = AnthropicChatModel(
        client,
        const NoopChatTrace(),
      ).stream(request()).listen(events.add, onError: events.add);
      await pumpEventQueue();
      client.respond(bytes.stream);
      bytes.add(utf8.encode(sse('message_start', {'type': 'message_start'})));
      await pumpEventQueue();

      await sub.cancel();

      expect(await _completedSoon(client.abortTrigger), isTrue);
      await pumpEventQueue();
      expect(bytesCancelled, isTrue);
    });

    test('취소 뒤에는 이벤트도 오류도 내지 않는다', () async {
      final bytes = StreamController<List<int>>();
      addTearDown(bytes.close);
      final client = _HangingClient();
      final events = <Object>[];
      var done = false;
      final sub = AnthropicChatModel(client, const NoopChatTrace())
          .stream(request())
          .listen(events.add, onError: events.add, onDone: () => done = true);
      await pumpEventQueue();
      client.respond(bytes.stream);
      bytes.add(
        utf8.encode(
          sse('content_block_start', {
            'index': 0,
            'content_block': {'type': 'text', 'text': ''},
          }),
        ),
      );
      await pumpEventQueue();

      await sub.cancel();
      bytes
        ..add(
          utf8.encode(
            sse('content_block_delta', {
              'index': 0,
              'delta': {'type': 'text_delta', 'text': 'late'},
            }),
          ),
        )
        ..addError(http.ClientException('x'));
      await pumpEventQueue();

      expect(events, isEmpty);
      expect(done, isFalse);
    });

    test('오류 본문을 받는 중에 취소하면 abortTrigger 가 끝나고 그 뒤 아무것도 내지 않는다', () async {
      for (final status in [400, 500]) {
        final bytes = StreamController<List<int>>();
        addTearDown(bytes.close);
        final client = _HangingClient();
        final events = <Object>[];
        var done = false;
        final sub = AnthropicChatModel(client, const NoopChatTrace())
            .stream(request())
            .listen(events.add, onError: events.add, onDone: () => done = true);
        await pumpEventQueue();
        client.respond(bytes.stream, status);
        bytes.add(utf8.encode('{"error":{"type":"billing'));
        await pumpEventQueue();

        await sub.cancel();
        expect(
          await _completedSoon(client.abortTrigger),
          isTrue,
          reason: '$status',
        );
        bytes.add(utf8.encode('_error"}}'));
        await pumpEventQueue();

        expect(events, isEmpty, reason: '$status');
        expect(done, isFalse, reason: '$status');
      }
    });

    test('오류 본문이 2초 안에 끝나지 않으면 상태 코드로 판정한다', () {
      fakeAsync((async) {
        final bytes = StreamController<List<int>>();
        final client = MockClient.streaming((r, b) async {
          await b.drain<void>();
          return http.StreamedResponse(bytes.stream, 429);
        });
        Object? error;
        AnthropicChatModel(
          client,
          const NoopChatTrace(),
        ).stream(request()).listen((_) {}, onError: (Object e) => error = e);
        async.flushMicrotasks();
        bytes.add(
          utf8.encode('{"error":{"type":"billing_error","message":"m"}}'),
        );
        async.elapse(const Duration(milliseconds: 1900));
        expect(error, isNull);
        async.elapse(const Duration(milliseconds: 200));
        expect(
          error,
          isA<ChatModelException>().having(
            (e) => e.kind,
            'kind',
            ChatModelErrorKind.rateLimited,
          ),
        );
        bytes.close();
        async.flushMicrotasks();
      });
    });

    test('정상 종료면 abortTrigger 는 끝나지 않는다', () async {
      final client = _HangingClient();
      final future = AnthropicChatModel(
        client,
        const NoopChatTrace(),
      ).stream(request()).toList();
      await pumpEventQueue();
      client.respond(Stream.value(utf8.encode(_textEvents('end_turn'))));

      final events = await future;

      expect(events.last, isA<ModelCompleted>());
      await pumpEventQueue();
      expect(await _completedSoon(client.abortTrigger), isFalse);
    });

    test('오류로 끝나도 abortTrigger 는 끝나지 않는다', () async {
      final client = _HangingClient();
      final future = AnthropicChatModel(
        client,
        const NoopChatTrace(),
      ).stream(request()).toList();
      await pumpEventQueue();
      client.respond(const Stream.empty(), 500);

      await expectLater(future, throwsA(isA<ChatModelException>()));
      await pumpEventQueue();
      expect(await _completedSoon(client.abortTrigger), isFalse);
    });

    test('상태 줄이 응답 대기 시간 안에 오지 않으면 요청을 끊고 network', () async {
      final trace = RecordingChatTrace();
      final client = _HangingClient();
      final future = AnthropicChatModel.withTimeouts(
        client,
        trace,
        responseTimeout: const Duration(milliseconds: 20),
      ).stream(request()).toList();

      await expectLater(future, isNetwork);

      expect(await _completedSoon(client.abortTrigger), isTrue);
      // 사용자 취소가 아니다 — abort 표시는 찍지 않는다.
      expect(trace.labels, isNot(contains(ChatTraceMark.abort)));
    });

    test('취소하면 trace 에 abort 를 찍는다', () async {
      final trace = RecordingChatTrace();
      final client = _HangingClient();
      final sub = AnthropicChatModel(
        client,
        trace,
      ).stream(request()).listen((_) {}, onError: (Object _) {});
      await pumpEventQueue();

      await sub.cancel();
      await pumpEventQueue();

      expect(trace.labels, [ChatTraceMark.req, ChatTraceMark.abort]);
    });

    test('정상 종료면 trace 에 abort 가 없다', () async {
      final trace = RecordingChatTrace();
      await AnthropicChatModel(
        clientOf([_textEvents('end_turn')]),
        trace,
      ).stream(request()).toList();

      expect(trace.labels, isNot(contains(ChatTraceMark.abort)));
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

    AnthropicChatModel modelOf(http.Client client) =>
        AnthropicChatModel(client, const NoopChatTrace());

    test('listModels 200 은 ok 이고 id · 표시 이름 · 만든 시각을 읽는다', () async {
      final result = await modelOf(
        listClient({
          'data': [
            {
              'id': 'claude-sonnet-x',
              'display_name': 'Claude Sonnet X',
              'created_at': '2026-10-01T00:00:00Z',
            },
          ],
          'has_more': false,
        }),
      ).listModels('sk-test');

      final models = (result as ModelListOk).models;
      expect(models, [
        ModelInfo(
          id: 'claude-sonnet-x',
          displayName: 'Claude Sonnet X',
          createdAt: DateTime.utc(2026, 10),
          supportsTools: true,
          supportsImages: true,
        ),
      ]);
      expect(models.single.supportsFastMode, isFalse);
    });

    test('listModels 는 GET /v1/models?limit=1000 에 키 헤더를 싣는다', () async {
      late http.BaseRequest req;
      await modelOf(
        listClient({'data': []}, onRequest: (r) => req = r),
      ).listModels('sk-test');

      expect(req.method, 'GET');
      expect(
        req.url.toString(),
        'https://api.anthropic.com/v1/models?limit=1000',
      );
      expect(req.headers['x-api-key'], 'sk-test');
      expect(req.headers['anthropic-version'], '2026-10-21');
    });

    group('페이지', () {
      const base = 'https://api.anthropic.com/v1/models?limit=1000';

      /// 요청 URL 마다 [respond] 로 응답한다. 받은 URL 을 [urls] 에 남긴다.
      MockClient pagedClient(
        List<String> urls,
        Future<http.StreamedResponse> Function(Uri url, int index) respond,
      ) => MockClient.streaming((r, b) async {
        await b.drain<void>();
        urls.add(r.url.toString());
        return respond(r.url, urls.length - 1);
      });

      http.StreamedResponse ok(String body) =>
          http.StreamedResponse(Stream.value(utf8.encode(body)), 200);

      test('픽스처는 손으로 만든 것(A1)으로 적혀 있다', () {
        expect(handMadeFixtures['anthropic/models_page1.json'], 'A1');
        expect(handMadeFixtures['anthropic/models_page2.json'], 'A1');
      });

      test('listModels 는 has_more 면 after_id 로 다음 쪽을 받아 합친다', () async {
        final urls = <String>[];
        final result = await modelOf(
          pagedClient(
            urls,
            (_, i) async =>
                ok(chatFixture('anthropic/models_page${i + 1}.json')),
          ),
        ).listModels('sk-test');

        expect(urls, [base, '$base&after_id=claude-sonnet-9-9']);
        expect((result as ModelListOk).models.map((m) => m.id), [
          'claude-opus-9-9',
          'claude-sonnet-9-9',
          'claude-haiku-9-8',
        ]);
      });

      test('has_more 가 true 여도 last_id 가 String 이 아니면 첫 쪽만', () async {
        final urls = <String>[];
        final result = await modelOf(
          pagedClient(
            urls,
            (_, _) async => ok(
              jsonEncode({
                'data': [
                  {'id': 'claude-a'},
                ],
                'has_more': true,
                'last_id': 3,
              }),
            ),
          ),
        ).listModels('k');
        expect(urls, [base]);
        expect((result as ModelListOk).models.map((m) => m.id), ['claude-a']);
      });

      test('둘째 쪽이 실패하면 첫 쪽만 ok', () async {
        for (final failure in ['500', '401', 'socket', 'timeout']) {
          final urls = <String>[];
          final result = await AnthropicChatModel.withTimeouts(
            pagedClient(urls, (_, i) async {
              if (i == 0) return ok(chatFixture('anthropic/models_page1.json'));
              return switch (failure) {
                '500' => http.StreamedResponse(const Stream.empty(), 500),
                '401' => http.StreamedResponse(const Stream.empty(), 401),
                'socket' => throw const SocketException('down'),
                _ => Completer<http.StreamedResponse>().future,
              };
            }),
            const NoopChatTrace(),
            listTimeout: const Duration(milliseconds: 50),
          ).listModels('k');

          expect(urls, hasLength(2), reason: failure);
          expect((result as ModelListOk).models.map((m) => m.id), [
            'claude-opus-9-9',
            'claude-sonnet-9-9',
          ], reason: failure);
        }
      });

      test('5쪽에서 멈춘다', () async {
        final urls = <String>[];
        final result = await modelOf(
          pagedClient(
            urls,
            (_, i) async => ok(
              jsonEncode({
                'data': [
                  {'id': 'claude-p$i'},
                ],
                'has_more': true,
                'last_id': 'claude-p$i',
              }),
            ),
          ),
        ).listModels('k');

        expect(urls, [
          base,
          for (var i = 0; i < 4; i++) '$base&after_id=claude-p$i',
        ]);
        expect((result as ModelListOk).models.map((m) => m.id), [
          for (var i = 0; i < 5; i++) 'claude-p$i',
        ]);
      });

      test('쪽마다 키 헤더를 싣는다', () async {
        final keys = <String?>[];
        await modelOf(
          MockClient.streaming((r, b) async {
            await b.drain<void>();
            keys.add(r.headers['x-api-key']);
            return ok(chatFixture('anthropic/models_page${keys.length}.json'));
          }),
        ).listModels('sk-test');
        expect(keys, ['sk-test', 'sk-test']);
      });
    });

    test('listModels 401 · 403 은 invalidKey', () async {
      for (final status in [401, 403]) {
        expect(
          await modelOf(listClient('{}', status: status)).listModels('k'),
          const ModelListResult.invalidKey(),
          reason: '$status',
        );
      }
    });

    test('listModels 500 · 429 · 529 는 unreachable', () async {
      for (final status in [500, 429, 529]) {
        expect(
          await modelOf(listClient('{}', status: status)).listModels('k'),
          const ModelListResult.unreachable(),
          reason: '$status',
        );
      }
    });

    test('listModels SocketException · 시간 초과는 unreachable', () async {
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
        await AnthropicChatModel.withTimeouts(
          hanging,
          const NoopChatTrace(),
          listTimeout: const Duration(milliseconds: 10),
        ).listModels('k'),
        const ModelListResult.unreachable(),
      );
    });

    test('기본 목록 대기 시간은 10초', () {
      expect(
        modelOf(MockClient((_) async => http.Response('', 200))).listTimeout,
        const Duration(seconds: 10),
      );
    });

    test('listModels 200 인데 본문이 JSON 이 아니면 ok(빈 목록)', () async {
      expect(
        await modelOf(listClient('<html>')).listModels('k'),
        const ModelListResult.ok([]),
      );
      expect(
        await modelOf(listClient({'nope': 1})).listModels('k'),
        const ModelListResult.ok([]),
      );
    });

    test('id 가 없는 항목은 건너뛴다', () async {
      final result = await modelOf(
        listClient({
          'data': [
            {'display_name': '이름만'},
            {'id': 3},
            'x',
            {'id': 'claude-a'},
          ],
        }),
      ).listModels('k');

      final models = (result as ModelListOk).models;
      expect(models.map((m) => m.id), ['claude-a']);
      expect(models.single.displayName, 'claude-a');
      expect(models.single.createdAt, isNull);
    });
  });

  group('stream 오류 본문의 error.type', () {
    Future<ChatModelException> errorOf(int status, String body) async {
      try {
        await run(clientOf([body], status: status));
      } on ChatModelException catch (e) {
        return e;
      }
      fail('no exception');
    }

    String typed(String type, [String message = 'm']) => jsonEncode({
      'type': 'error',
      'error': {'type': type, 'message': message},
    });

    test('stream 오류: error.type billing_error 는 quotaExceeded', () async {
      expect(
        (await errorOf(400, typed('billing_error'))).kind,
        ChatModelErrorKind.quotaExceeded,
      );
    });

    test('402 는 quotaExceeded', () async {
      expect((await errorOf(402, '')).kind, ChatModelErrorKind.quotaExceeded);
    });

    test('not_found_error · 404 는 modelUnavailable', () async {
      expect(
        (await errorOf(400, typed('not_found_error'))).kind,
        ChatModelErrorKind.modelUnavailable,
      );
      expect(
        (await errorOf(404, 'not json')).kind,
        ChatModelErrorKind.modelUnavailable,
      );
    });

    test('400 invalid_request_error 는 server', () async {
      expect(
        (await errorOf(400, typed('invalid_request_error'))).kind,
        ChatModelErrorKind.server,
      );
    });

    test('401 은 본문 없이도 invalidKey', () async {
      expect((await errorOf(401, '')).kind, ChatModelErrorKind.invalidKey);
    });

    test('error.type 이 상태 코드보다 앞선다', () async {
      expect(
        (await errorOf(500, typed('rate_limit_error'))).kind,
        ChatModelErrorKind.rateLimited,
      );
      expect(
        (await errorOf(500, typed('overloaded_error'))).kind,
        ChatModelErrorKind.overloaded,
      );
      expect(
        (await errorOf(400, typed('authentication_error'))).kind,
        ChatModelErrorKind.invalidKey,
      );
      expect(
        (await errorOf(400, typed('permission_error'))).kind,
        ChatModelErrorKind.invalidKey,
      );
    });

    test('오류 본문의 message 는 예외에 없다', () async {
      final e = await errorOf(
        400,
        typed('billing_error', 'sk-ant-secret 크레딧 없음'),
      );
      expect(e.kind, ChatModelErrorKind.quotaExceeded);
      expect(e.toString(), isNot(contains('secret')));
      expect(e.toString(), isNot(contains('message')));
    });

    test('오류 본문이 16KB 를 넘으면 type 을 읽지 않고 상태 코드로 판정한다', () async {
      final big = jsonEncode({
        'type': 'error',
        'error': {'type': 'billing_error', 'message': 'x' * (17 * 1024)},
      });
      expect((await errorOf(500, big)).kind, ChatModelErrorKind.server);
      expect((await errorOf(429, big)).kind, ChatModelErrorKind.rateLimited);
    });

    test('SSE error 이벤트도 error.type 으로 판정한다', () async {
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

      expect(await kindFor('billing_error'), ChatModelErrorKind.quotaExceeded);
      expect(await kindFor('rate_limit_error'), ChatModelErrorKind.rateLimited);
    });
  });

  group('진행 이벤트', () {
    AnthropicChatModel model(
      http.Client client, {
      bool? progressNotes,
      ChatTrace trace = const NoopChatTrace(),
    }) => AnthropicChatModel.withTimeouts(
      client,
      trace,
      progressNotes: progressNotes,
    );

    Future<List<ModelEvent>> runWith(
      List<String> chunks, {
      bool progressNotes = true,
      ChatTrace trace = const NoopChatTrace(),
    }) => model(
      clientOf(chunks),
      progressNotes: progressNotes,
      trace: trace,
    ).stream(request()).toList();

    /// thinking 블록 하나(조각 [deltas] · 서명 SIG) + 끝.
    List<String> thinkingRound(List<String> deltas) => [
      sse('message_start', {'type': 'message_start'}),
      sse('content_block_start', {
        'index': 0,
        'content_block': {'type': 'thinking', 'thinking': ''},
      }),
      for (final d in deltas)
        sse('content_block_delta', {
          'index': 0,
          'delta': {'type': 'thinking_delta', 'thinking': d},
        }),
      sse('content_block_delta', {
        'index': 0,
        'delta': {'type': 'signature_delta', 'signature': 'SIG'},
      }),
      sse('content_block_stop', {'index': 0}),
      sse('message_delta', {
        'delta': {'stop_reason': 'end_turn'},
      }),
      sse('message_stop', {}),
    ];

    List<String> progressOf(List<ModelEvent> events) =>
        events.whereType<ModelProgress>().map((e) => e.text).toList();

    test('progressNotesDefault 는 false 이고 기본 생성자는 그것을 따른다', () {
      expect(AnthropicChatModel.progressNotesDefault, isFalse);
      expect(
        AnthropicChatModel(
          clientOf(const []),
          const NoopChatTrace(),
        ).progressNotes,
        AnthropicChatModel.progressNotesDefault,
      );
      expect(
        model(clientOf(const []), progressNotes: true).progressNotes,
        isTrue,
      );
    });

    test(
      'progressNotes 가 켜지면 thinking.display=updates 와 beta 헤더 둘을 보낸다',
      () async {
        late http.BaseRequest req;
        late Map<String, dynamic> body;
        await model(
          clientOf(
            thinkingRound(const []),
            onRequest: (r, b) {
              req = r;
              body = jsonDecode(b) as Map<String, dynamic>;
            },
          ),
          progressNotes: true,
        ).stream(request()).toList();
        expect(body['thinking'], {'type': 'adaptive', 'display': 'updates'});
        expect(
          req.headers['anthropic-beta'],
          'server-side-fallback-2026-07-01,thinking-display-updates-2026-08-18',
        );
      },
    );

    test('progressNotes 가 꺼지면 thinking 키가 없고 beta 헤더는 fallback 하나다 — '
        '본문이 기본 생성자와 같다', () async {
      final requests = <(String?, String)>[];
      MockClient recording() => clientOf(
        thinkingRound(const []),
        onRequest: (r, b) => requests.add((r.headers['anthropic-beta'], b)),
      );
      await model(
        recording(),
        progressNotes: false,
      ).stream(request(messages: const [ChatMessage.user('hi')])).toList();
      await AnthropicChatModel(
        recording(),
        const NoopChatTrace(),
      ).stream(request(messages: const [ChatMessage.user('hi')])).toList();
      final (beta, body) = requests.first;
      expect(beta, 'server-side-fallback-2026-07-01');
      expect((jsonDecode(body) as Map).containsKey('thinking'), isFalse);
      expect(requests.last, requests.first);
    });

    test('노트를 받지 않는 모델이면 켜져 있어도 thinking 키를 보내지 않는다', () async {
      late http.BaseRequest req;
      late Map<String, dynamic> body;
      await model(
        clientOf(
          thinkingRound(const []),
          onRequest: (r, b) {
            req = r;
            body = jsonDecode(b) as Map<String, dynamic>;
          },
        ),
        progressNotes: true,
      ).stream(request(model: 'claude-haiku-x')).toList();
      expect(body.containsKey('thinking'), isFalse);
      expect(req.headers['anthropic-beta'], 'server-side-fallback-2026-07-01');
    });

    test('노트를 받는 모델 접두사는 opus-5 · sonnet-5 다', () async {
      for (final (id, expected) in const [
        ('claude-opus-5-5', true),
        ('claude-sonnet-5', true),
        ('claude-sonnet-5-1', true),
        ('claude-opus-4-7', false),
        ('claude-haiku-4-5', false),
      ]) {
        late Map<String, dynamic> body;
        await model(
          clientOf(
            thinkingRound(const []),
            onRequest: (_, b) => body = jsonDecode(b) as Map<String, dynamic>,
          ),
          progressNotes: true,
        ).stream(request(model: id)).toList();
        expect(body.containsKey('thinking'), expected, reason: id);
      }
    });

    test('thinking 블록이 열리면 thinking() 을 낸다', () async {
      final events = await runWith(thinkingRound(const []));
      expect(events.first, isA<ModelThinking>());
      expect(events.last, isA<ModelCompleted>());
      expect(events.whereType<ModelProgress>(), isEmpty);
    });

    test('redacted_thinking 블록도 thinking() 을 낸다', () async {
      final events = await runWith([
        sse('content_block_start', {
          'index': 0,
          'content_block': {'type': 'redacted_thinking', 'data': 'X'},
        }),
        sse('content_block_stop', {'index': 0}),
        sse('message_delta', {
          'delta': {'stop_reason': 'end_turn'},
        }),
        sse('message_stop', {}),
      ], progressNotes: false);
      expect(events.first, isA<ModelThinking>());
      expect(events, hasLength(2));
    });

    test('비어 있지 않은 thinking_delta 는 누적 글로 progress 를 낸다', () async {
      final events = await runWith(
        thinkingRound(const ['  ', '지난주 기상 ', '기록을 볼게요']),
      );
      expect(progressOf(events), ['지난주 기상', '지난주 기상 기록을 볼게요']);
      expect(events.first, isA<ModelThinking>());
      expect(events.last, isA<ModelCompleted>());
    });

    test(
      'progressNotes 가 꺼지면 thinking_delta 에 글이 있어도 progress 를 내지 않는다',
      () async {
        final events = await runWith(
          thinkingRound(const ['지난주 기상 ', '기록을 볼게요']),
          progressNotes: false,
        );
        expect(events.whereType<ModelProgress>(), isEmpty);
        expect(events.first, isA<ModelThinking>());
      },
    );

    test('중단 문구는 progress 로 내지 않는다', () async {
      final events = await runWith(
        thinkingRound(const [
          'This part of the ',
          'response was interrupted ',
          'before it finished.',
        ]),
      );
      expect(events.whereType<ModelProgress>(), isEmpty);
    });

    test('중단 문구의 접두사로 시작했지만 다른 글이면 그 글을 하나만 낸다', () async {
      final events = await runWith(
        thinkingRound(const ['This part', ' of my plan']),
      );
      expect(progressOf(events), ['This part of my plan']);
    });

    test('접두사인 채로 블록이 닫히면 그때 낸다', () async {
      final chunks = thinkingRound(const ['This part', ' of the']);
      final events = await runWith(chunks);
      expect(progressOf(events), ['This part of the']);
      expect(events.last, isA<ModelCompleted>());
    });

    test(
      'tool_use 블록 시작에 toolCallStarted, 정지에 toolCallReady(input) 를 낸다',
      () async {
        final events = <ModelEvent>[];
        final order = <String>[];
        final client = MockClient.streaming((r, b) async {
          await b.drain<void>();
          final controller = StreamController<List<int>>();
          void push(String chunk, String tag) {
            order.add(tag);
            controller.add(utf8.encode(chunk));
          }

          unawaited(() async {
            push(
              sse('content_block_start', {
                'index': 0,
                'content_block': {
                  'type': 'tool_use',
                  'id': 'tu1',
                  'name': 'search_diary',
                  'input': {},
                },
              }),
              'start',
            );
            await Future<void>.delayed(Duration.zero);
            push(
              sse('content_block_delta', {
                'index': 0,
                'delta': {
                  'type': 'input_json_delta',
                  'partial_json': '{"from":"2026-06-01"}',
                },
              }),
              'delta',
            );
            await Future<void>.delayed(Duration.zero);
            push(sse('content_block_stop', {'index': 0}), 'stop');
            push(
              sse('message_delta', {
                'delta': {'stop_reason': 'tool_use'},
              }),
              'md',
            );
            push(sse('message_stop', {}), 'ms');
            await controller.close();
          }());
          return http.StreamedResponse(controller.stream, 200);
        });
        await for (final e in model(
          client,
          progressNotes: false,
        ).stream(request())) {
          events.add(e);
          if (e is ModelToolCallStarted) order.add('event:started');
        }
        // 입력 조각이 오기 전에 이미 toolCallStarted 를 냈다.
        expect(
          order.indexOf('event:started'),
          lessThan(order.indexOf('delta')),
        );
        expect(events, hasLength(3));
        final started = events[0] as ModelToolCallStarted;
        expect((started.id, started.name), ('tu1', 'search_diary'));
        final ready = events[1] as ModelToolCallReady;
        expect((ready.id, ready.name), ('tu1', 'search_diary'));
        expect(ready.input, {'from': '2026-06-01'});
        final done = events[2] as ModelCompleted;
        expect(done.message.parts, const [
          AssistantPart.toolCall(
            id: 'tu1',
            name: 'search_diary',
            input: {'from': '2026-06-01'},
          ),
        ]);
      },
    );

    test('tool_use 의 id · name 이 문자열이 아니면 진행 이벤트를 건너뛴다(블록 처리는 지금대로)', () async {
      final events = <ModelEvent>[];
      Object? error;
      await model(
            clientOf([
              sse('content_block_start', {
                'index': 0,
                'content_block': {'type': 'tool_use', 'id': 1, 'name': null},
              }),
              sse('content_block_stop', {'index': 0}),
              sse('message_delta', {
                'delta': {'stop_reason': 'tool_use'},
              }),
              sse('message_stop', {}),
            ]),
            progressNotes: true,
          )
          .stream(request())
          .handleError((Object e) => error = e)
          .forEach(events.add);
      expect(events.whereType<ModelToolCallStarted>(), isEmpty);
      expect(events.whereType<ModelToolCallReady>(), isEmpty);
      // 모양이 어긋난 tool_use 는 지금처럼 completed 에서 server 로 끝난다.
      expect(
        error,
        isA<ChatModelException>().having(
          (e) => e.kind,
          'kind',
          ChatModelErrorKind.server,
        ),
      );
    });

    test(
      '노트를 내도 completed 의 vendorState thinking 블록(글 · 서명)은 받은 그대로다',
      () async {
        final events = await runWith(thinkingRound(const ['  지난주 ', '기록  ']));
        final state =
            (events.last as ModelCompleted).message.vendorState!
                as AnthropicTurnState;
        expect(
          state.content,
          equals([
            {'type': 'thinking', 'thinking': '  지난주 기록  ', 'signature': 'SIG'},
          ]),
        );
        expect((events.last as ModelCompleted).message.parts, isEmpty);
      },
    );

    test('trace 에 progress(chars) 를 찍고 노트 글은 data 에 없다', () async {
      final trace = RecordingChatTrace();
      await runWith(thinkingRound(const ['비밀 ', '노트']), trace: trace);
      expect(trace.dataOf(ChatTraceMark.progress), [
        {'chars': 2},
        {'chars': 5},
      ]);
      final all = trace.marks.map((m) => '${m.$2}').join();
      expect(all, isNot(contains('비밀')));
      expect(all, isNot(contains('노트')));
    });
  });
}
