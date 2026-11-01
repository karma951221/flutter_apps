import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/chat/sse_lines.dart';

Stream<List<int>> _bytes(String text) => Stream.value(utf8.encode(text));

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
}
