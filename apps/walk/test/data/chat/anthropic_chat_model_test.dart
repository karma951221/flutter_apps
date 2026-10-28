import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:walk/data/chat/anthropic_chat_model.dart';
import 'package:walk/domain/chat/chat_model.dart';

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

Future<List<ModelEvent>> run(MockClient client) => AnthropicChatModel(client)
    .stream(
      apiKey: 'sk-test',
      system: 'sys',
      messages: const [],
      tools: const [],
    )
    .toList();

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
    await AnthropicChatModel(client)
        .stream(
          apiKey: 'sk-test',
          system: 'sys',
          messages: [
            {'role': 'user', 'content': 'hi'},
          ],
          tools: [
            {'name': 't'},
          ],
        )
        .toList();
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
    expect(done.stopReason, 'end_turn');
    expect(done.content, [
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
    expect((events.last as ModelCompleted).content.single['text'], '한글');
  });

  test('thinking 블록을 서명과 함께 그대로 돌려준다', () async {
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
    expect((events.last as ModelCompleted).content, [
      {'type': 'thinking', 'thinking': '음...', 'signature': 'SIG'},
      {'type': 'text', 'text': 'a'},
    ]);
  });

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
    expect(done.stopReason, 'tool_use');
    expect(done.content[0]['input'], {'from': '2026-10-01'});
    expect(done.content[0]['id'], 'tu_1');
    expect(done.content[1]['input'], <String, Object?>{});
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
    ).stream(apiKey: 'k', system: 's', messages: const [], tools: const []);
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
            responseTimeout: const Duration(milliseconds: 20),
          )
          .stream(apiKey: 'k', system: 's', messages: const [], tools: const [])
          .toList(),
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
            idleTimeout: const Duration(milliseconds: 20),
          )
          .stream(apiKey: 'k', system: 's', messages: const [], tools: const [])
          .toList(),
      isNetwork,
    );
    await controller.close();
  });

  test('기본 대기 시간은 응답 60초, SSE 유휴 90초', () {
    final model = AnthropicChatModel(
      MockClient((_) async => http.Response('', 200)),
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
}
