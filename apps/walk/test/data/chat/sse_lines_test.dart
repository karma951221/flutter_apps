import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:walk/data/chat/sse_lines.dart';
import 'package:walk/domain/chat/chat_trace.dart';

import '../../support/recording_chat_trace.dart';

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
  test('toString 에 payload 가 없다', () {
    const event = SseEvent(event: 'content_block_delta', data: '{"text":"비밀"}');
    expect(event.toString(), isNot(contains('비밀')));
  });

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

  group('typeFallback', () {
    Future<List<SseEvent>> readTyped(String text) => sseEvents(
      _bytes(text),
      idleTimeout: const Duration(seconds: 5),
      typeFallback: true,
    ).toList();

    test('event 줄이 없으면 data 의 type 을 이름으로 쓴다', () async {
      expect(await readTyped('data: {"type":"a.b","x":1}\n\n'), [
        const SseEvent(event: 'a.b', data: '{"type":"a.b","x":1}'),
      ]);
    });

    test('event 줄이 있으면 그것이 먼저다', () async {
      expect(
        (await readTyped('event: e\ndata: {"type":"t"}\n\n')).single.event,
        'e',
      );
    });

    test('type 이 없거나 JSON 이 아니면 내지 않는다', () async {
      expect(
        await readTyped('data: {"x":1}\n\ndata: nope\n\ndata: {"type":2}\n\n'),
        isEmpty,
      );
    });

    test('기본은 끔 — event 줄 없는 덩어리는 버린다', () async {
      expect(await _read(_bytes('data: {"type":"a"}\n\n')), isEmpty);
    });
  });

  group('untilAbort', () {
    test('abort 가 끝나면 원본 구독을 끊고 닫는다', () async {
      var cancelled = false;
      final source = StreamController<List<int>>(
        onCancel: () => cancelled = true,
      );
      addTearDown(source.close);
      final abort = Completer<void>();
      final got = <List<int>>[];
      var done = false;
      untilAbort(
        source.stream,
        abort.future,
      ).listen(got.add, onDone: () => done = true);
      source.add([1]);
      await pumpEventQueue();
      abort.complete();
      await pumpEventQueue();
      expect(cancelled, isTrue);
      expect(done, isTrue);
      expect(got, [
        [1],
      ]);
    });

    test('abort 없이 원본이 끝나면 그대로 끝난다', () async {
      expect(
        await untilAbort(
          Stream.fromIterable([
            [1],
            [2],
          ]),
          Completer<void>().future,
        ).toList(),
        [
          [1],
          [2],
        ],
      );
    });
  });

  group('abortableStream', () {
    test('끝나기 전 취소하면 abort 를 끝내고 trace 에 abort, 이후 아무것도 없다', () async {
      final trace = RecordingChatTrace();
      final source = StreamController<int>();
      addTearDown(source.close);
      late Completer<void> abort;
      final got = <Object>[];
      final sub = abortableStream<int>((a) {
        abort = a;
        return source.stream;
      }, trace: trace).listen(got.add, onError: got.add);
      source.add(1);
      await pumpEventQueue();

      await sub.cancel();

      expect(abort.isCompleted, isTrue);
      expect(trace.labels, [ChatTraceMark.abort]);
      source
        ..add(2)
        ..addError(StateError('late'));
      await pumpEventQueue();
      expect(got, [1]);
    });

    test('정상 종료 뒤 취소는 abort 가 아니다', () async {
      final trace = RecordingChatTrace();
      late Completer<void> abort;
      final values = await abortableStream<int>((a) {
        abort = a;
        return Stream.fromIterable([1, 2]);
      }, trace: trace).toList();
      expect(values, [1, 2]);
      expect(abort.isCompleted, isFalse);
      expect(trace.labels, isEmpty);
    });

    test('오류는 그대로 전하고 abort 하지 않는다', () async {
      late Completer<void> abort;
      await expectLater(
        abortableStream<int>((a) {
          abort = a;
          return Stream.error(StateError('x'));
        }, trace: const NoopChatTrace()),
        emitsError(isStateError),
      );
      expect(abort.isCompleted, isFalse);
    });

    test('run 이 이미 abort 를 끝냈어도 취소가 던지지 않는다', () async {
      final source = StreamController<int>();
      addTearDown(source.close);
      final trace = RecordingChatTrace();
      final sub = abortableStream<int>((a) {
        a.complete();
        return source.stream;
      }, trace: trace).listen((_) {});
      await pumpEventQueue();
      await sub.cancel();
      expect(trace.labels, isEmpty);
    });
  });
}
