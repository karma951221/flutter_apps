/// 하루 걸음 목표의 범위. 설정 슬라이더와 저장소 clamp 가 같은 값을 쓴다.
abstract final class StepGoal {
  static const defaultSteps = 10000;
  static const min = 2000;
  static const max = 30000;
  static const step = 1000;

  static int clamp(int value) =>
      ((value.clamp(min, max) / step).round() * step).clamp(min, max);
}
