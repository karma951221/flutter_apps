import '../entity/alarm.dart';

/// 울림 패키지 경계. id 는 `packageId`(알람 id * 100 + 날짜 index).
abstract interface class AlarmScheduler {
  /// 패키지에 걸린 회차: packageId → 울릴 시각.
  /// 시각까지 받는 이유는 스누즈된 회차를 알아보기 위해서다(`AlarmUseCase.sync`).
  Future<Map<int, DateTime>> scheduled();

  /// 지금 울리는 중인 packageId.
  Future<Set<int>> ringingIds();

  /// 같은 id 면 덮어쓴다(울리는 중이면 멈추고 다시 건다).
  Future<void> schedule(int packageId, DateTime at, Alarm alarm);

  Future<void> cancel(int packageId);

  /// 울리는 중 끄기.
  Future<void> stop(int packageId);
}
