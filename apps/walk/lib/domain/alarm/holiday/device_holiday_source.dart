/// 폰 캘린더에서 읽은 공휴일 하루. [date] 는 로컬 자정.
typedef DeviceHoliday = ({DateTime date, String name});

/// 폰 캘린더(안드로이드 `CalendarContract`)의 휴일 캘린더를 읽는다.
/// 권한 없음 · 휴일 캘린더 없음 · 범위에 일정 없음 · 실패는 모두 null — 부르는 쪽은 내장 표로 간다.
abstract interface class DeviceHolidaySource {
  /// [from]–[to](날짜, 양 끝 포함)의 공휴일(쉬는 날만, 기념일 제외).
  Future<List<DeviceHoliday>?> read(DateTime from, DateTime to);

  /// 고른 휴일 캘린더의 표시 이름.
  Future<String?> calendarName();
}
