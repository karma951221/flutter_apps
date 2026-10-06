import 'entity/alarm.dart';
import 'entity/alarm_reminder.dart';
import 'entity/alarm_trigger.dart';
import 'holiday/holiday_calendar.dart';

/// "곧 울림" 미리 알림 리드 시간. 디버그 확인용으로 `--dart-define=WALK_REMINDER_LEAD_MINUTES`.
const alarmSoonLead = Duration(
  minutes: int.fromEnvironment('WALK_REMINDER_LEAD_MINUTES', defaultValue: 30),
);

/// 공휴일 미리 알림 리드 시간. 디버그 확인용으로 `--dart-define=WALK_HOLIDAY_LEAD_MINUTES`.
const alarmHolidayLead = Duration(
  minutes: int.fromEnvironment('WALK_HOLIDAY_LEAD_MINUTES', defaultValue: 1440),
);

/// [alarm] 의 회차([triggers], 보통 `triggersOf` 의 14일치)에 띄울 미리 알림(웨이브 3 스펙 §3.3).
///
/// - soon: `remindBefore` 이고 `ringAt - soonLead` 가 [now] 뒤일 때. 울릴 때가 그보다 가까우면 만들지 않는다.
/// - holiday: 반복 알람 · [holidayReminder] 켬 · 울릴 날이 공휴일 · `ringAt` 이 [now] 뒤일 때.
///   띄울 시각이 이미 지났으면 [now] — 다음 sync 에서 바로 띄운다.
List<AlarmReminder> remindersOf(
  Alarm alarm,
  List<AlarmTrigger> triggers,
  DateTime now, {
  required HolidayCalendar holidays,
  required bool holidayReminder,
  Duration soonLead = alarmSoonLead,
  Duration holidayLead = alarmHolidayLead,
}) => [
  for (final AlarmTrigger(:packageId, :alarmId, at: ringAt) in triggers) ...[
    if (alarm.remindBefore && ringAt.subtract(soonLead).isAfter(now))
      AlarmReminder(
        id: reminderId(packageId, ReminderKind.soon),
        packageId: packageId,
        alarmId: alarmId,
        kind: ReminderKind.soon,
        at: ringAt.subtract(soonLead),
        ringAt: ringAt,
      ),
    if (!alarm.isOneShot && holidayReminder && ringAt.isAfter(now))
      if (holidays.nameOf(ringAt) case final name?)
        AlarmReminder(
          id: reminderId(packageId, ReminderKind.holiday),
          packageId: packageId,
          alarmId: alarmId,
          kind: ReminderKind.holiday,
          at: _latest(ringAt.subtract(holidayLead), now),
          ringAt: ringAt,
          holidayName: name,
        ),
  ],
];

DateTime _latest(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
