import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/walk/entity/goal_progress.dart';
import 'package:walk/domain/walk/entity/step_goal.dart';

void main() {
  group('StepGoal.clamp', () {
    test('범위 밖은 끝값으로', () {
      expect(StepGoal.clamp(500), StepGoal.min);
      expect(StepGoal.clamp(99999), StepGoal.max);
    });
    test('1,000 단위로 반올림', () => expect(StepGoal.clamp(7499), 7000));
  });

  group('GoalProgress', () {
    test('0보', () {
      const p = GoalProgress(steps: 0, goal: 10000);
      expect(p.ratio, 0);
      expect(p.reached, isFalse);
      expect(p.remainingSteps, 10000);
      expect(p.remainingMeters(null), isNull);
      expect(p.remainingMeters(0), isNull);
    });
    test('정확히 목표면 달성, 남은 0', () {
      const p = GoalProgress(steps: 10000, goal: 10000);
      expect(p.reached, isTrue);
      expect(p.remainingSteps, 0);
      expect(p.overSteps, 0);
    });
    test('초과는 비율 1 초과 · overSteps', () {
      const p = GoalProgress(steps: 12500, goal: 10000);
      expect(p.ratio, 1.25);
      expect(p.overSteps, 2500);
    });
    test('남은 거리는 오늘 보폭으로', () {
      const p = GoalProgress(steps: 5000, goal: 10000);
      expect(p.remainingMeters(3500), closeTo(3500, 0.001)); // 0.7m × 5000
    });
  });

  group('shouldCelebrate', () {
    final today = DateTime(2026, 10, 3);
    test(
      '달성 + 축하 기록 없음',
      () => expect(
        shouldCelebrate(steps: 10000, goal: 10000, today: today),
        isTrue,
      ),
    );
    test(
      '어제 축하했으면 오늘 다시',
      () => expect(
        shouldCelebrate(
          steps: 10000,
          goal: 10000,
          today: today,
          lastCelebratedOn: DateTime(2026, 10, 2),
        ),
        isTrue,
      ),
    );
    test(
      '오늘 이미 축하',
      () => expect(
        shouldCelebrate(
          steps: 20000,
          goal: 10000,
          today: today,
          lastCelebratedOn: today,
        ),
        isFalse,
      ),
    );
    test(
      '미달',
      () => expect(
        shouldCelebrate(steps: 9999, goal: 10000, today: today),
        isFalse,
      ),
    );
  });
}
