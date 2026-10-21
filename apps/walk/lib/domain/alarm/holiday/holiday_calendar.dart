import 'package:freezed_annotation/freezed_annotation.dart';

part 'holiday_calendar.freezed.dart';

/// 날짜가 공휴일(쉬는 날)인지 답한다. 출처는 폰 캘린더가 먼저, 없으면 앱 내장 표다
/// (웨이브 3 스펙 §2).
abstract interface class HolidayCalendar {
  /// [date] 의 날짜(시각은 무시)가 공휴일이면 그 이름, 아니면 null.
  String? nameOf(DateTime date);

  /// 지금 답하는 출처. 설정 탭이 사용자에게 보여 준다.
  HolidaySource get source;
}

/// 공휴일 출처.
@freezed
sealed class HolidaySource with _$HolidaySource {
  /// 폰 캘린더(`CalendarContract`)의 휴일 캘린더. [calendarName] 은 표시 이름(모르면 빈 문자열).
  const factory HolidaySource.device({required String calendarName}) = DeviceCalendarHolidays;

  /// 앱에 들어 있는 표(`korean_holidays.dart`). [firstYear]–[lastYear] 만 안다.
  const factory HolidaySource.bundled({required int firstYear, required int lastYear}) =
      BundledHolidays;
}

/// 폰 캘린더 캐시를 새로 읽는다. 앱 시작 · 하루 sync · 권한을 새로 받았을 때 부른다.
abstract interface class HolidayRefresher {
  /// 오늘 이미 읽었으면 건너뛴다. [force] 면 그래도 읽는다. 던지지 않는다.
  Future<void> refresh({bool force = false});

  /// 캐시를 새로 쓸 때마다 알린다(broadcast). 출처를 보여 주는 화면이 확인 순서와 상관없이
  /// 최신 출처를 다시 읽는다. 같은 isolate 의 갱신만 알린다 — 헤드리스 엔진의 갱신은 복귀 때 읽는다.
  Stream<void> get refreshed;
}
