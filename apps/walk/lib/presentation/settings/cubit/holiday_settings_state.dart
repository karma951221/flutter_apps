import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:permission/permission.dart';

import '../../../domain/alarm/holiday/holiday_calendar.dart';

part 'holiday_settings_state.freezed.dart';

/// 설정 탭 "알람" 섹션 — 공휴일 미리 알림 스위치와 공휴일 출처 · 캘린더 권한.
@freezed
class HolidaySettingsState with _$HolidaySettingsState {
  /// 공휴일 미리 알림(`AppSettings.holidayReminder`).
  @override
  final bool holidayReminder;

  /// 지금 공휴일을 읽는 곳. null = 아직 확인 중.
  @override
  final HolidaySource? source;

  /// 캘린더 읽기 권한. null = 아직 확인 중(또는 확인 실패).
  @override
  final PermissionStatus? calendar;

  const HolidaySettingsState({this.holidayReminder = true, this.source, this.calendar});
}
