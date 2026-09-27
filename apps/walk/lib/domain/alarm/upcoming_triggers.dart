import 'entity/alarm.dart';
import 'entity/alarm_trigger.dart';

/// 반복 알람을 미리 걸어 두는 기간. 앱이 열릴 때마다 채운다(스펙 §5).
const alarmScheduleWindow = Duration(days: 14);

/// 스누즈 간격. 설정 항목 없이 고정이다.
const alarmSnoozeDuration = Duration(minutes: 5);

/// [alarm] 이 `now` 뒤 · `now + window` 이하에 울릴 시각들(오름차순).
List<DateTime> upcomingTriggers(
  Alarm alarm,
  DateTime now, {
  Duration window = alarmScheduleWindow,
}) {
  if (!alarm.enabled) return const [];
  final days = window.inDays;
  final limit = DateTime(
    now.year,
    now.month,
    now.day + days,
    now.hour,
    now.minute,
    now.second,
    now.millisecond,
    now.microsecond,
  );
  bool inWindow(DateTime at) => at.isAfter(now) && !at.isAfter(limit);

  if (alarm.isOneShot) {
    final at = alarm.oneShotAt;
    return at != null && inWindow(at) ? [at] : const [];
  }
  return [
    for (var n = 0; n <= days; n++)
      if (DateTime(now.year, now.month, now.day + n, alarm.hour, alarm.minute) case final at
          when alarm.repeat.contains(Weekday.of(at)) && inWindow(at))
        at,
  ];
}

/// `now` 뒤에 처음 오는 `hour:minute`. 1회성 알람을 켤 때 `oneShotAt` 을 정한다.
DateTime nextOccurrence(int hour, int minute, DateTime now) {
  final today = DateTime(now.year, now.month, now.day, hour, minute);
  return today.isAfter(now) ? today : DateTime(now.year, now.month, now.day + 1, hour, minute);
}

/// [alarm] 의 회차를 패키지 id 와 함께.
List<AlarmTrigger> triggersOf(Alarm alarm, DateTime now) => [
  for (final at in upcomingTriggers(alarm, now))
    AlarmTrigger(packageId: packageId(alarm.id, triggerIndex(at)), alarmId: alarm.id, at: at),
];

/// 켜진 알람 전체에서 가장 이른 회차. 없으면 null.
AlarmTrigger? nextTrigger(Iterable<Alarm> alarms, DateTime now) {
  AlarmTrigger? earliest;
  for (final alarm in alarms) {
    final triggers = triggersOf(alarm, now);
    if (triggers.isEmpty) continue;
    if (earliest == null || triggers.first.at.isBefore(earliest.at)) earliest = triggers.first;
  }
  return earliest;
}
