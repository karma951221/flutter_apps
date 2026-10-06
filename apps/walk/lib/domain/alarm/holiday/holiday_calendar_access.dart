import 'package:permission/permission.dart';

import '../../settings/repository/settings_repository.dart';
import 'holiday_calendar.dart';

/// 폰 캘린더 읽기 권한(`READ_CALENDAR`). 공휴일 미리 알림을 처음 켤 때(알람 저장 · 설정 스위치)
/// 묻는다. 거부하면 내장 표를 쓴다. 요청기가 세션 기억을 가지므로 DI 싱글턴이다.
class HolidayCalendarAccess {
  HolidayCalendarAccess({
    required this.calendar,
    required this.refresher,
    required SettingsRepository settings,
  }) : _settings = settings;

  final PermissionRequester calendar;
  final HolidayRefresher refresher;
  final SettingsRepository _settings;

  Future<PermissionStatus> check() => calendar.check();

  /// 아직 안 물었으면 묻는다. 이번에 새로 허용되면 오늘 이미 읽은 캐시(권한 없음 → 내장 표)를
  /// 버리고 바로 폰 캘린더를 다시 읽는다.
  Future<PermissionStatus> ensure() async {
    final before = await calendar.check();
    final after = await calendar.ensure();
    if (before != PermissionStatus.granted && after == PermissionStatus.granted) {
      await refresher.refresh(force: true);
    }
    return after;
  }

  /// 공휴일 미리 알림(`AppSettings.holidayReminder`, 기본 켬)이 켜져 있을 때만 [ensure].
  /// 반복 알람을 저장한 뒤 부른다 — 기본 켬이라 처음 반복 알람을 저장할 때 묻게 된다.
  Future<void> ensureIfReminding() async {
    if (_settings.load().holidayReminder) await ensure();
  }
}
