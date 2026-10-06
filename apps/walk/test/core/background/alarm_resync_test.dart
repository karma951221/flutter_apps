import 'package:flutter_test/flutter_test.dart';
import 'package:walk/core/background/alarm_resync.dart';

void main() {
  late List<String> calls;

  setUp(() => calls = []);

  Future<void> Function() record(String name, {bool fail = false}) => () async {
    calls.add(name);
    if (fail) throw StateError('$name 실패');
  };

  test('init → 공휴일 갱신 → sync → done 순서로 부른다', () async {
    await runAlarmResync(
      init: record('init'),
      refreshHolidays: record('holidays'),
      sync: record('sync'),
      done: record('done'),
    );

    expect(calls, ['init', 'holidays', 'sync', 'done']);
  });

  test('공휴일 갱신이 실패해도 sync 와 done 을 부른다', () async {
    await runAlarmResync(
      init: record('init'),
      refreshHolidays: record('holidays', fail: true),
      sync: record('sync'),
      done: record('done'),
    );

    expect(calls, ['init', 'holidays', 'sync', 'done']);
  });

  test('init 이 실패하면 공휴일 갱신 · sync 를 건너뛰고 done 을 부른다', () async {
    await runAlarmResync(
      init: record('init', fail: true),
      refreshHolidays: record('holidays'),
      sync: record('sync'),
      done: record('done'),
    );

    expect(calls, ['init', 'done']);
  });

  test('sync 가 실패해도 done 을 한 번 부르고 예외를 올리지 않는다', () async {
    await runAlarmResync(
      init: record('init'),
      refreshHolidays: record('holidays'),
      sync: record('sync', fail: true),
      done: record('done'),
    );

    expect(calls, ['init', 'holidays', 'sync', 'done']);
  });

  test('done 이 실패해도 예외를 올리지 않고 다시 부르지 않는다', () async {
    await runAlarmResync(
      init: record('init'),
      refreshHolidays: record('holidays'),
      sync: record('sync'),
      done: record('done', fail: true),
    );

    expect(calls.where((c) => c == 'done'), hasLength(1));
  });
}
