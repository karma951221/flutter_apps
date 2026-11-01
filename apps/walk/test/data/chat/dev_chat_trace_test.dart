import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/chat/dev_chat_trace.dart';
import 'package:walk/domain/chat/chat_trace.dart';

/// 시간을 손으로 고정하는 Stopwatch.
class _FakeStopwatch implements Stopwatch {
  int now = 0;

  @override
  int get elapsedMilliseconds => now;

  @override
  void start() {}

  @override
  void reset() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeStopwatch watch;
  late List<String> lines;
  late DevChatTrace trace;

  setUp(() {
    watch = _FakeStopwatch();
    lines = [];
    trace = DevChatTrace(emit: lines.add, stopwatch: () => watch);
  });

  void at(int ms, String label, [Map<String, Object?> data = const {}]) {
    watch.now = ms;
    trace.mark(label, data);
  }

  test('enabled 는 true', () {
    expect(trace.enabled, isTrue);
  });

  test('요약 한 줄에 라운드 · 블록 · 도구 · 프레임 표시가 들어간다', () {
    trace.begin();
    at(0, ChatTraceMark.send);
    at(12, ChatTraceMark.key);
    at(600, ChatTraceMark.round, {'n': 1});
    at(600, ChatTraceMark.req, {
      'vendor': 'anthropic',
      'model': 'claude-opus-5-5',
      'fast': false,
    });
    at(610, ChatTraceMark.head);
    at(640, ChatTraceMark.first);
    at(640, ChatTraceMark.blockStart, {'kind': 'thinking'});
    at(3900, ChatTraceMark.blockStop, {'kind': 'thinking'});
    at(3950, ChatTraceMark.blockStart, {
      'kind': 'tool_use',
      'tool': 'search_diary',
    });
    at(4010, ChatTraceMark.blockStop, {'kind': 'tool_use'});
    at(4020, ChatTraceMark.msgStop, {
      'stop': 'toolUse',
      'in': 2310,
      'out': 180,
      'cacheRead': 0,
      'cacheWrite': 0,
    });
    at(4030, ChatTraceMark.toolStart, {'tool': 'search_diary'});
    at(4040, ChatTraceMark.firstVisible);
    at(4090, ChatTraceMark.toolEnd, {'tool': 'search_diary', 'n': 5});
    at(4390, ChatTraceMark.round, {'n': 2});
    at(4390, ChatTraceMark.req, {
      'vendor': 'anthropic',
      'model': 'claude-opus-5-5',
      'fast': false,
    });
    at(4400, ChatTraceMark.head);
    at(4420, ChatTraceMark.first);
    at(4420, ChatTraceMark.blockStart, {'kind': 'text'});
    // 23 조각: 간격 45ms 21번 + 235ms 1번 = 1180ms, 가장 큰 조각 18자.
    var t = 6100;
    for (var i = 0; i < 23; i++) {
      if (i > 0) t += i == 10 ? 235 : 45;
      at(t, ChatTraceMark.textDelta, {'chars': i == 3 ? 18 : 5});
      if (i == 0) at(6120, ChatTraceMark.firstGlyph);
    }
    expect(t, 7280);
    at(7290, ChatTraceMark.blockStop, {'kind': 'text'});
    at(7300, ChatTraceMark.msgStop, {
      'stop': 'endTurn',
      'in': 4870,
      'out': 240,
      'cacheRead': 2100,
      'cacheWrite': 0,
    });
    at(7350, ChatTraceMark.done);
    trace.end();

    expect(lines, [
      'chat.trace q=1 vendor=anthropic model=claude-opus-5-5 fast=0 rounds=2 '
          'key=12 '
          'r1{head=610 first=640 think=640-3900 tool:search_diary=3950-4010 '
          'stop=4020 in=2310 out=180} '
          'tool:search_diary=4030-4090(n=5) '
          'r2{head=4400 first=4420 firstText=6100 deltas=23/1180ms max=18ch '
          'gap~45ms stop=7300 in=4870 out=240 cacheRead=2100} '
          'firstVisible=4040 firstGlyph=6120 done=7350',
    ]);
  });

  test('textDelta 개수 · 첫~마지막 간격 · 최대 조각 · 간격 중앙값을 계산한다', () {
    trace.begin();
    at(0, ChatTraceMark.round, {'n': 1});
    at(0, ChatTraceMark.textDelta, {'chars': 5});
    at(40, ChatTraceMark.textDelta, {'chars': 18});
    at(100, ChatTraceMark.textDelta, {'chars': 7});
    trace.end();

    expect(lines.single, contains('deltas=3/100ms max=18ch gap~50ms'));
  });

  test('stop 종류가 toolUse · endTurn 이 아니면 시간 옆에 남긴다', () {
    trace.begin();
    at(0, ChatTraceMark.round, {'n': 1});
    at(300, ChatTraceMark.msgStop, {'stop': 'maxTokens', 'in': 1, 'out': 2});
    trace.end();

    expect(lines.single, contains('stop=300(maxTokens) in=1 out=2'));
  });

  test('허용하지 않은 data 키는 버린다', () {
    trace.begin();
    at(5, ChatTraceMark.req, {
      'vendor': 'anthropic',
      'text': '비밀 질문',
      'apiKey': 'sk-ant-secret',
    });
    at(6, ChatTraceMark.toolStart, {'tool': 'search_diary', 'query': '비밀 검색어'});
    at(7, ChatTraceMark.toolEnd, {'tool': 'search_diary', 'n': 1});
    trace.end();

    final line = lines.single;
    expect(line, contains('vendor=anthropic'));
    expect(line, isNot(contains('비밀')));
    expect(line, isNot(contains('sk-')));
  });

  test('end 뒤에는 비워져 다음 begin 이 새 질문이다', () {
    trace.begin();
    at(10, ChatTraceMark.key);
    at(20, ChatTraceMark.done);
    trace.end();
    trace.begin();
    at(30, ChatTraceMark.done);
    trace.end();

    expect(lines, hasLength(2));
    expect(lines[0], startsWith('chat.trace q=1 '));
    expect(lines[0], contains('key=10'));
    expect(lines[1], startsWith('chat.trace q=2 '));
    expect(lines[1], isNot(contains('key=')));
    expect(lines[1], contains('done=30'));
  });

  test('begin 없이 mark · end 해도 던지지 않는다', () {
    expect(() {
      trace
        ..mark(ChatTraceMark.textDelta, {'chars': 3})
        ..mark(ChatTraceMark.done)
        ..end()
        ..end();
    }, returnsNormally);
    expect(lines, isEmpty);
  });
}
