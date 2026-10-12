import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/lock/lock_attempts.dart';
import 'package:walk/domain/lock/lock_policy.dart';

void main() {
  final now = DateTime(2026, 10, 12, 9);

  LockAttempts failTimes(int n) {
    var attempts = const LockAttempts();
    for (var i = 0; i < n; i++) {
      attempts = LockPolicy.wrongSecret(attempts, now);
    }
    return attempts;
  }

  group('틀린 PIN · 패턴', () {
    test('4회 실패까지는 차단하지 않는다', () {
      final attempts = failTimes(4);

      expect(attempts.failures, 4);
      expect(attempts.blockedUntil, isNull);
      expect(LockPolicy.remaining(attempts, now), isNull);
    });

    test('5회째에 30초 차단하고 횟수를 0 으로 되돌린다', () {
      final attempts = failTimes(5);

      expect(attempts.blockedUntil, now.add(const Duration(seconds: 30)));
      expect(attempts.failures, 0);
      expect(attempts.longBlock, isFalse);
      expect(LockPolicy.remaining(attempts, now), const Duration(seconds: 30));
      expect(
        LockPolicy.remaining(attempts, now.add(const Duration(seconds: 29))),
        const Duration(seconds: 1),
      );
    });

    test('30초가 지나면 차단이 풀리고 횟수는 0 이다', () {
      final attempts = failTimes(5);
      final later = now.add(const Duration(seconds: 30));

      expect(LockPolicy.remaining(attempts, later), isNull);
      expect(attempts.failures, 0);
    });

    test('차단이 풀린 뒤 다시 4회 틀려도 차단하지 않는다', () {
      var attempts = failTimes(5);
      final later = now.add(const Duration(minutes: 1));
      for (var i = 0; i < 4; i++) {
        attempts = LockPolicy.wrongSecret(attempts, later);
      }

      expect(LockPolicy.remaining(attempts, later), isNull);
    });
  });

  group('폰 인증 실패', () {
    test('24시간 차단한다', () {
      final attempts = LockPolicy.deviceAuthFailed(now);

      expect(attempts.longBlock, isTrue);
      expect(attempts.blockedUntil, now.add(const Duration(hours: 24)));
    });

    test('24시간 - 1초까지 차단, 24시간에 풀린다', () {
      final attempts = LockPolicy.deviceAuthFailed(now);

      expect(
        LockPolicy.remaining(
          attempts,
          now.add(const Duration(hours: 24) - const Duration(seconds: 1)),
        ),
        const Duration(seconds: 1),
      );
      expect(
        LockPolicy.remaining(attempts, now.add(const Duration(hours: 24))),
        isNull,
      );
    });
  });

  test('성공하면 시도 기록을 초기화한다', () {
    expect(LockPolicy.success(), const LockAttempts());
    expect(LockPolicy.success().failures, 0);
    expect(LockPolicy.success().blockedUntil, isNull);
    expect(LockPolicy.success().longBlock, isFalse);
  });

  group('시계가 거꾸로 감', () {
    test('30초 차단 시작 전으로 가면 남은 시간을 전체 30초로 본다', () {
      final attempts = failTimes(5);

      expect(
        LockPolicy.remaining(attempts, now.subtract(const Duration(hours: 1))),
        const Duration(seconds: 30),
      );
    });

    test('24시간 차단 시작 전으로 가면 남은 시간을 전체 24시간으로 본다', () {
      final attempts = LockPolicy.deviceAuthFailed(now);

      expect(
        LockPolicy.remaining(attempts, now.subtract(const Duration(days: 3))),
        const Duration(hours: 24),
      );
    });
  });

  group('PatternRule.withSkipped', () {
    test('가로로 건너뛴 가운데 점을 넣는다', () {
      expect(PatternRule.withSkipped([0, 2]), [0, 1, 2]);
      expect(PatternRule.withSkipped([3, 5]), [3, 4, 5]);
    });

    test('대각선으로 건너뛴 가운데 점을 넣는다', () {
      expect(PatternRule.withSkipped([0, 8]), [0, 4, 8]);
      expect(PatternRule.withSkipped([2, 6]), [2, 4, 6]);
    });

    test('세로로 건너뛴 가운데 점을 넣는다', () {
      expect(PatternRule.withSkipped([1, 7]), [1, 4, 7]);
    });

    test('이미 쓴 가운데 점은 다시 넣지 않는다', () {
      expect(PatternRule.withSkipped([1, 0, 2]), [1, 0, 2]);
    });

    test('가운데 점이 없는 이동은 그대로 둔다', () {
      expect(PatternRule.withSkipped([0, 5, 6]), [0, 5, 6]);
      expect(PatternRule.withSkipped([0, 1, 2, 5]), [0, 1, 2, 5]);
    });
  });
}
