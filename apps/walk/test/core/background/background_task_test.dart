import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/core/background/background_task.dart';

void main() {
  late List<String> calls;

  setUp(() => calls = []);

  Future<void> Function() record(String name, {bool fail = false}) => () async {
    calls.add(name);
    if (fail) throw StateError('$name 실패');
  };

  Future<void> Function(bool ok) recordDone({bool fail = false}) => (ok) async {
    calls.add('done($ok)');
    if (fail) throw StateError('done 실패');
  };

  group('runBackgroundTask', () {
    test('init → task → done(true) 순서로 부른다', () async {
      await runBackgroundTask(
        init: record('init'),
        task: record('task'),
        done: recordDone(),
      );

      expect(calls, ['init', 'task', 'done(true)']);
    });

    test('init 이 실패하면 task 를 건너뛰고 done(false) 를 부른다', () async {
      await runBackgroundTask(
        init: record('init', fail: true),
        task: record('task'),
        done: recordDone(),
      );

      expect(calls, ['init', 'done(false)']);
    });

    test('task 가 실패하면 done(false) 를 부르고 예외를 올리지 않는다', () async {
      await runBackgroundTask(
        init: record('init'),
        task: record('task', fail: true),
        done: recordDone(),
      );

      expect(calls, ['init', 'task', 'done(false)']);
    });

    test('done 이 실패해도 예외를 올리지 않고 다시 부르지 않는다', () async {
      await runBackgroundTask(
        init: record('init'),
        task: record('task'),
        done: recordDone(fail: true),
      );

      expect(calls, ['init', 'task', 'done(true)']);
    });
  });

  group('resyncTask (하루 sync · 시간대)', () {
    test('공휴일 캐시를 갱신한 뒤 sync 한다', () async {
      await resyncTask(
        refreshHolidays: record('holidays'),
        sync: record('sync'),
      )();

      expect(calls, ['holidays', 'sync']);
    });

    test('공휴일 갱신이 실패해도 sync 한다', () async {
      await resyncTask(
        refreshHolidays: record('holidays', fail: true),
        sync: record('sync'),
      )();

      expect(calls, ['holidays', 'sync']);
    });

    test('sync 가 실패하면 실패로 끝난다(done(false))', () async {
      await runBackgroundTask(
        init: record('init'),
        task: resyncTask(
          refreshHolidays: record('holidays'),
          sync: record('sync', fail: true),
        ),
        done: recordDone(),
      );

      expect(calls, ['init', 'holidays', 'sync', 'done(false)']);
    });
  });

  group('reminderActionPackageId (헤드리스 진입점 인자)', () {
    test('["skip", "<packageId>"] 에서 packageId 를 읽는다', () {
      expect(reminderActionPackageId(['skip', '1203']), 1203);
    });

    test('모르는 동작 · 빠진 인자 · 숫자 아님은 FormatException', () {
      for (final args in [
        <String>[],
        ['skip'],
        ['dismiss', '1203'],
        ['skip', 'abc'],
      ]) {
        expect(
          () => reminderActionPackageId(args),
          throwsFormatException,
          reason: '$args',
        );
      }
    });
  });

  group('awaitBackgroundIdle', () {
    final messenger =
        TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger;
    late List<String> methods;

    void answer(Future<Object?> Function() reply) {
      methods = [];
      messenger.setMockMethodCallHandler(backgroundChannel, (call) {
        methods.add(call.method);
        return reply();
      });
    }

    tearDown(() => messenger.setMockMethodCallHandler(backgroundChannel, null));

    test('시간 한도는 10초', () {
      expect(backgroundIdleTimeout, const Duration(seconds: 10));
    });

    test('walk/background 의 awaitIdle 을 부르고 응답할 때까지 기다린다', () async {
      final idle = Completer<Object?>();
      answer(() => idle.future);

      var done = false;
      final waiting = awaitBackgroundIdle().then((_) => done = true);
      await pumpEventQueue();
      expect(methods, ['awaitIdle']);
      expect(done, isFalse);

      idle.complete(null);
      await waiting;
      expect(done, isTrue);
    });

    test('응답이 없으면 시간 한도 뒤 그냥 끝난다', () async {
      answer(() => Completer<Object?>().future);
      await awaitBackgroundIdle(timeout: const Duration(milliseconds: 20));
      expect(methods, ['awaitIdle']);
    });

    test('채널이 없거나 오류면 바로 끝난다(던지지 않는다)', () async {
      await awaitBackgroundIdle();
      answer(() async => throw PlatformException(code: 'boom'));
      await awaitBackgroundIdle();
      expect(methods, ['awaitIdle']);
    });
  });
}
