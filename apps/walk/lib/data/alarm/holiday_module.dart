import 'package:injectable/injectable.dart';
import 'package:permission/permission.dart';

import '../../domain/alarm/holiday/holiday_calendar.dart';
import '../../domain/alarm/holiday/holiday_calendar_access.dart';
import '../../domain/settings/repository/settings_repository.dart';
import 'cached_holiday_calendar.dart';
import 'calendar_permission_source.dart';

/// [CachedHolidayCalendar] 하나를 공휴일 판정 · 캐시 갱신 두 얼굴로 등록한다.
@module
abstract class HolidayModule {
  @lazySingleton
  HolidayCalendar holidayCalendar(CachedHolidayCalendar calendar) => calendar;

  @lazySingleton
  HolidayRefresher holidayRefresher(CachedHolidayCalendar calendar) => calendar;

  /// 읽기 권한(`READ_CALENDAR`)만 묻는다 — `permission_handler` 의 캘린더 권한은 쓰기도 요구한다.
  @lazySingleton
  HolidayCalendarAccess holidayCalendarAccess(
    CachedHolidayCalendar calendar,
    SettingsRepository settings,
  ) => HolidayCalendarAccess(
    calendar: PermissionRequester(CalendarPermissionSource()),
    refresher: calendar,
    settings: settings,
  );
}
