import '../entity/alarm.dart';
import '../entity/alarm_reminder.dart';

/// 걸렸거나 떠 있는 미리 알림 하나: 띄울 시각과 그 미리 알림이 알리는 울릴 시각.
///
/// id 는 회차(날짜)로만 정해져 알람 시각을 바꿔도 같으므로, 떠 있는 알림이 지금 회차의 것인지
/// [ringAt] 으로 가린다.
typedef ScheduledReminder = ({DateTime at, DateTime ringAt});

/// 미리 알림 경계(웨이브 3 스펙 §3.3). 네이티브가 AlarmManager 로 걸고 띄운다. id 는 [reminderId].
abstract interface class ReminderScheduler {
  /// 걸렸거나 떠 있는(울릴 시각 전) 미리 알림: id → 띄울 시각 · 울릴 시각.
  ///
  /// 띄운 뒤에는 사용자가 알림을 닫아도([울리기] · 밀어 지우기) 울릴 시각까지 계속 돌려준다.
  /// 빠지면 sync 가 아직 안 띄운 것으로 보고 다시 건다 — 띄울 시각이 지난 공휴일 알림은 바로 다시 뜬다.
  Future<Map<int, ScheduledReminder>> scheduled();

  /// 같은 id 면 덮어쓴다. 띄울 시각이 지났으면 바로 띄운다. 문구는 [alarm] 으로 만든다.
  Future<void> schedule(AlarmReminder reminder, Alarm alarm);

  /// 예약과 떠 있는 알림을 모두 지운다.
  Future<void> cancel(int reminderId);
}
