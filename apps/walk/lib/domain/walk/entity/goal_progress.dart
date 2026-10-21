import 'package:freezed_annotation/freezed_annotation.dart';

part 'goal_progress.freezed.dart';

/// 오늘 걸음과 목표의 관계. 비율은 1 을 넘을 수 있다(링은 1 에서 멈추고 숫자만 넘친다).
@freezed
class GoalProgress with _$GoalProgress {
  @override
  final int steps;
  @override
  final int goal;

  const GoalProgress({required this.steps, required this.goal});

  double get ratio => goal <= 0 ? 0 : steps / goal;
  bool get reached => steps >= goal;
  int get remainingSteps => reached ? 0 : goal - steps;
  int get overSteps => reached ? steps - goal : 0;
}

/// 달성했고 오늘 아직 축하하지 않았으면 참. 날짜는 자정 기준으로 비교한다.
bool shouldCelebrate({
  required int steps,
  required int goal,
  required DateTime today,
  DateTime? lastCelebratedOn,
}) {
  if (steps < goal) return false;
  if (lastCelebratedOn == null) return true;
  // domain 은 Flutter(DateUtils)에 기대지 않는다.
  return lastCelebratedOn.year != today.year ||
      lastCelebratedOn.month != today.month ||
      lastCelebratedOn.day != today.day;
}
