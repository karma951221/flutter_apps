import '../entity/alarm.dart';

/// 패키지에 걸린 회차 하나. [signature] 는 걸 때 붙인 설정 지문([AlarmScheduler.signatureOf]),
/// 지문 없이 걸린 옛 회차는 빈 문자열이다.
typedef ScheduledRing = ({DateTime at, String signature});

/// 울림 패키지 경계. id 는 `packageId`(알람 id * 100 + 날짜 index).
abstract interface class AlarmScheduler {
  /// 패키지에 걸린 회차: packageId → 울릴 시각 · 설정 지문.
  /// 시각까지 받는 이유는 스누즈된 회차를 알아보기 위해서다(`AlarmUseCase.sync`).
  /// 지문은 시각이 같아도 소리 · 진동 같은 설정이 바뀐 회차를 다시 걸기 위해서다.
  Future<Map<int, ScheduledRing>> scheduled();

  /// [alarm] 으로 지금 [schedule] 하면 회차에 붙을 지문. 울림에 영향을 주는 값만 담는다.
  String signatureOf(Alarm alarm);

  /// 지금 울리는 중인 packageId.
  Future<Set<int>> ringingIds();

  /// 같은 id 면 덮어쓴다(울리는 중이면 멈추고 다시 건다).
  /// [snoozeCount] 는 이 회차가 지금까지 스누즈된 횟수다. `Alarm.snoozeLimit` 에 닿으면
  /// 그 울림에는 스누즈가 없다. 새 회차는 0.
  Future<void> schedule(
    int packageId,
    DateTime at,
    Alarm alarm, {
    int snoozeCount = 0,
  });

  /// 걸려 있는(울리는 중 포함) 회차가 지금까지 스누즈된 횟수. 알림 스누즈는 포크가 세므로
  /// 패키지 예약에서 읽는다. 없으면 0.
  Future<int> snoozeCountOf(int packageId);

  Future<void> cancel(int packageId);

  /// 패키지에 걸린 예약을 모두 지금 시간대로 다시 건다. 패키지는 시각을 오프셋 없는 벽시계로
  /// 저장해, 시간대가 바뀐 뒤 부르면 새 시간대의 같은 벽시계로 옮겨 건다. ([scheduled] 도 그
  /// 벽시계를 돌려주므로 시간대가 바뀐 뒤 AlarmManager 의 절대 시각과 어긋난 것은 보이지 않는다.)
  Future<void> rearmAll();

  /// 울리는 중 끄기.
  Future<void> stop(int packageId);
}
