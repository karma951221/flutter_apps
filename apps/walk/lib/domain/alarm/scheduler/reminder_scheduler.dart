import '../entity/alarm.dart';
import '../entity/alarm_reminder.dart';

/// 미리 알림 경계(웨이브 3 스펙 §3.3). 네이티브가 AlarmManager 로 걸고 띄운다. id 는 [reminderId].
abstract interface class ReminderScheduler {
  /// 걸렸거나 떠 있는(울릴 시각 전) 미리 알림: id → 띄울 시각.
  Future<Map<int, DateTime>> scheduled();

  /// 같은 id 면 덮어쓴다. 띄울 시각이 지났으면 바로 띄운다. 문구는 [alarm] 으로 만든다.
  Future<void> schedule(AlarmReminder reminder, Alarm alarm);

  /// 예약과 떠 있는 알림을 모두 지운다.
  Future<void> cancel(int reminderId);
}
