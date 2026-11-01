import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:walk/data/chat/sse_lines.dart';

Stream<List<int>> _bytes(String text) => Stream.value(utf8.encode(text));

/// 받은 요청을 잡아 두고 빈 200 응답을 돌려준다.
class _CapturingClient extends http.BaseClient {
  http.BaseRequest? request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request;
    return http.StreamedResponse(const Stream.empty(), 200);
  }
}

Future<List<SseEvent>> _read(Stream<List<int>> bytes) =>
    sseEvents(bytes, idleTimeout: const Duration(seconds: 5)).toList();

void main() {
  test('한 이벤트의 event 와 data 를 낸다', () async {
    final events = await _read(_bytes('event: a\ndata: {"x":1}\n\n'));
    expect(events, [const SseEvent(event: 'a', data: '{"x":1}')]);
  });

  test('여러 data 줄은 줄바꿈으로 잇는다', () async {
    final events = await _read(_bytes('event: a\ndata: 1\ndata: 2\n\n'));
    expect(events.single.data, '1\n2');
  });

  test('event 가 없거나 data 가 없으면 내지 않는다', () async {
    final events = await _read(
      _bytes('data: 1\n\nevent: a\n\nevent: b\ndata: 2\n\n'),
    );
    expect(events, [const SseEvent(event: 'b', data: '2')]);
  });

  test('UTF-8 이 바이트 중간에서 잘려도 복원한다', () async {
    final all = utf8.encode('event: a\ndata: 한\n\n');
    final cut = all.indexOf(0xED) + 1;
    final events = await _read(
      Stream.fromIterable([all.sublist(0, cut), all.sublist(cut)]),
    );
    expect(events.single.data, '한');
  });

  test('끝에 빈 줄 없이 끝나도 남은 이벤트를 낸다', () async {
    final events = await _read(_bytes('event: a\ndata: 1'));
    expect(events, [const SseEvent(event: 'a', data: '1')]);
  });

  test('주석 줄(:)은 버린다', () async {
    final events = await _read(_bytes(': ping\nevent: a\ndata: 1\n\n'));
    expect(events, [const SseEvent(event: 'a', data: '1')]);
  });

  test('줄 사이가 idleTimeout 을 넘으면 TimeoutException', () async {
    final controller = StreamController<List<int>>();
    addTearDown(controller.close);
    controller.add(utf8.encode('event: a\n'));
    expect(
      sseEvents(
        controller.stream,
        idleTimeout: const Duration(milliseconds: 10),
      ).toList(),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('abortableSend 는 AbortableRequest 에 trigger · 헤더 · 본문을 담는다', () async {
    final client = _CapturingClient();
    final trigger = Completer<void>();
    final url = Uri.parse('https://example.test/v1');

    final response = await abortableSend(
      client,
      method: 'POST',
      url: url,
      headers: const {'x-a': '1', 'content-type': 'application/json'},
      body: '{"k":1}',
      abortTrigger: trigger.future,
    );

    expect(response.statusCode, 200);
    final request = client.request;
    expect(request, isA<http.Abortable>());
    expect(request, isA<http.Request>());
    expect((request! as http.Abortable).abortTrigger, same(trigger.future));
    expect(request.method, 'POST');
    expect(request.url, url);
    expect(request.headers['x-a'], '1');
    expect(request.headers['content-type'], contains('application/json'));
    expect((request as http.Request).body, '{"k":1}');
  });
}
