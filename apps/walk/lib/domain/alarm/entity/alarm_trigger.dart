import 'package:freezed_annotation/freezed_annotation.dart';

part 'alarm_trigger.freezed.dart';

/// 패키지에 거는 알람 한 회차.
@freezed
class AlarmTrigger with _$AlarmTrigger {
  @override
  final int packageId;
  @override
  final int alarmId;
  @override
  final DateTime at;

  const AlarmTrigger({
    required this.packageId,
    required this.alarmId,
    required this.at,
  });
}

/// 알람 하나가 가질 수 있는 패키지 id 수.
const packageIdsPerAlarm = 100;

/// `alarmId * 100 + index` (index 0..99).
int packageId(int alarmId, int index) {
  assert(index >= 0 && index < packageIdsPerAlarm);
  return alarmId * packageIdsPerAlarm + index;
}

int alarmIdOf(int packageId) => packageId ~/ packageIdsPerAlarm;

/// 회차의 index 는 **날짜로** 정한다(에포크 이후 일수 % 100). 알람 하나는 하루에 한 번만
/// 울리고 예약 창이 14일이라 창 안에서 겹치지 않는다. 목록 순번으로 정하면 오늘 회차가
/// 지나는 순간 내일 회차가 index 0 을 물려받아, 울린 뒤 스누즈한 회차를 덮어쓴다.
int triggerIndex(DateTime at) {
  final days =
      DateTime.utc(at.year, at.month, at.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  return days % packageIdsPerAlarm;
}
