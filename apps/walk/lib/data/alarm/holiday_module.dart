import 'package:injectable/injectable.dart';
import 'package:permission/permission.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../domain/alarm/holiday/holiday_calendar.dart';
import '../../domain/alarm/holiday/holiday_calendar_access.dart';
import '../../domain/settings/repository/settings_repository.dart';
import 'cached_holiday_calendar.dart';
import 'permission_handler_source.dart';

/// [CachedHolidayCalendar] 하나를 공휴일 판정 · 캐시 갱신 두 얼굴로 등록한다.
@module
abstract class HolidayModule {
  @lazySingleton
  HolidayCalendar holidayCalendar(CachedHolidayCalendar calendar) => calendar;

  @lazySingleton
  HolidayRefresher holidayRefresher(CachedHolidayCalendar calendar) => calendar;

  /// `calendarFullAccess` 는 매니페스트에 선언된 것만 묻는다 — 이 앱은 `READ_CALENDAR` 하나.
  @lazySingleton
  HolidayCalendarAccess holidayCalendarAccess(
    CachedHolidayCalendar calendar,
    SettingsRepository settings,
  ) => HolidayCalendarAccess(
    calendar: PermissionRequester(PermissionHandlerSource(ph.Permission.calendarFullAccess)),
    refresher: calendar,
    settings: settings,
  );
}
