import 'package:freezed_annotation/freezed_annotation.dart';

part 'alarm_reminder.freezed.dart';

/// 미리 알림 종류. `index` 가 [reminderId] 에 들어가므로 순서를 바꾸지 않는다.
enum ReminderKind {
  /// 울리기 [alarmSoonLead] 전 "곧 알람이 울려요" + [이번만 끄기]. 알람별 `remindBefore`.
  soon,

  /// 반복 알람이 공휴일에 울리면 [alarmHolidayLead] 전 + [다음 알람 건너뛰기] · [울리기].
  holiday,
}

/// 알람 회차 하나에 대한 미리 알림. 네이티브(`walk/reminders`)가 [at] 에 띄우고, [ringAt] 이
/// 지나면 지운다.
@freezed
class AlarmReminder with _$AlarmReminder {
  /// [reminderId] 로 정한다.
  @override
  final int id;

  /// 미리 알리는 회차의 패키지 id. 알림 액션이 이것으로 `AlarmUseCase.skipOccurrence` 를 부른다.
  @override
  final int packageId;
  @override
  final int alarmId;
  @override
  final ReminderKind kind;

  /// 띄울 시각.
  @override
  final DateTime at;

  /// 울릴 시각.
  @override
  final DateTime ringAt;

  /// [ReminderKind.holiday] 의 공휴일 이름(없으면 날짜만 쓴다).
  @override
  final String? holidayName;

  const AlarmReminder({
    required this.id,
    required this.packageId,
    required this.alarmId,
    required this.kind,
    required this.at,
    required this.ringAt,
    this.holidayName,
  });
}

/// `1_000_000 + packageId * 2 + kind.index`. 패키지 id(최대 999_999) · 포크 자리표시 알림(973_422)과
/// 겹치지 않고, 안드로이드 알림 id · 요청 코드(int32) 안이다.
int reminderId(int packageId, ReminderKind kind) =>
    1000000 + packageId * 2 + kind.index;
