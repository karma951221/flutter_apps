import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/domain/lock/relock_timer.dart';

void main() {
  final pausedAt = DateTime(2026, 10, 12, 9);

  bool lockAfter(
    Duration elapsed,
    RelockDelay delay, {
    bool pickingMedia = false,
  }) => RelockTimer.shouldLock(
    pausedAt: pausedAt,
    now: pausedAt.add(elapsed),
    delay: delay,
    pickingMedia: pickingMedia,
  );

  test('기본 설정은 꺼짐 · PIN · 1분', () {
    expect(RelockDelay.fallback, RelockDelay.minute1);
    expect(const LockConfig().relockDelay, RelockDelay.minute1);
    expect(const LockConfig().enabled, isFalse);
    expect(const LockConfig().method, LockMethod.pin);
  });

  test('즉시는 0초에도 잠근다', () {
    expect(lockAfter(Duration.zero, RelockDelay.immediate), isTrue);
  });

  test('30초 경계', () {
    expect(
      lockAfter(const Duration(milliseconds: 29999), RelockDelay.seconds30),
      isFalse,
    );
    expect(
      lockAfter(const Duration(seconds: 30), RelockDelay.seconds30),
      isTrue,
    );
  });

  test('1분 경계', () {
    expect(
      lockAfter(const Duration(milliseconds: 59999), RelockDelay.minute1),
      isFalse,
    );
    expect(lockAfter(const Duration(minutes: 1), RelockDelay.minute1), isTrue);
  });

  test('5분 경계', () {
    expect(
      lockAfter(
        const Duration(minutes: 5) - const Duration(milliseconds: 1),
        RelockDelay.minutes5,
      ),
      isFalse,
    );
    expect(lockAfter(const Duration(minutes: 5), RelockDelay.minutes5), isTrue);
  });

  test('미디어를 고르는 동안이면 10분이 지나도 잠그지 않는다', () {
    expect(
      lockAfter(
        const Duration(minutes: 10),
        RelockDelay.immediate,
        pickingMedia: true,
      ),
      isFalse,
    );
  });

  test('백그라운드로 간 적이 없으면 잠그지 않는다', () {
    expect(
      RelockTimer.shouldLock(
        pausedAt: null,
        now: pausedAt,
        delay: RelockDelay.immediate,
        pickingMedia: false,
      ),
      isFalse,
    );
  });

  test('시계가 거꾸로 가면 잠근다', () {
    expect(
      RelockTimer.shouldLock(
        pausedAt: pausedAt,
        now: pausedAt.subtract(const Duration(seconds: 1)),
        delay: RelockDelay.minutes5,
        pickingMedia: false,
      ),
      isTrue,
    );
  });
}
