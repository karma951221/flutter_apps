import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar.dart';
import 'package:walk/domain/alarm/holiday/korean_holidays.dart';

void main() {
  const calendar = KoreanHolidayCalendar();

  test('출처는 내장 표 2026–2027', () {
    expect(calendar.source, const HolidaySource.bundled(firstYear: 2026, lastYear: 2027));
  });

  group('2026', () {
    test('정규 공휴일', () {
      expect(calendar.nameOf(DateTime(2026, 1, 1)), '신정');
      expect(calendar.nameOf(DateTime(2026, 2, 17)), '설날');
      expect(calendar.nameOf(DateTime(2026, 5, 1)), '노동절');
      expect(calendar.nameOf(DateTime(2026, 7, 17)), '제헌절');
      expect(calendar.nameOf(DateTime(2026, 9, 25)), '추석');
      expect(calendar.nameOf(DateTime(2026, 10, 9)), '한글날');
      expect(calendar.nameOf(DateTime(2026, 12, 25)), '성탄절');
    });

    test('대체공휴일', () {
      expect(calendar.nameOf(DateTime(2026, 3, 2)), '삼일절 대체공휴일');
      expect(calendar.nameOf(DateTime(2026, 5, 25)), '부처님 오신 날 대체공휴일');
      expect(calendar.nameOf(DateTime(2026, 8, 17)), '광복절 대체공휴일');
      expect(calendar.nameOf(DateTime(2026, 10, 5)), '개천절 대체공휴일');
    });

    test('선거일', () {
      expect(calendar.nameOf(DateTime(2026, 6, 3)), '지방선거');
    });

    test('주말과 겹친 공휴일도 표에 있다', () {
      expect(calendar.nameOf(DateTime(2026, 6, 6)), '현충일');
      expect(calendar.nameOf(DateTime(2026, 9, 26)), '추석 다음 날');
    });

    test('모두 22일(조사 표의 행 수)', () {
      final days = koreanHolidays.keys.where((k) => k ~/ 10000 == 2026);
      expect(days, hasLength(22));
    });
  });

  group('2027', () {
    test('설 연휴와 대체공휴일', () {
      expect(calendar.nameOf(DateTime(2027, 2, 6)), '설날 전날');
      expect(calendar.nameOf(DateTime(2027, 2, 7)), '설날');
      expect(calendar.nameOf(DateTime(2027, 2, 8)), '설날 다음 날');
      expect(calendar.nameOf(DateTime(2027, 2, 9)), '설날 대체공휴일');
    });

    test('노동절 · 제헌절 첫 대체공휴일', () {
      expect(calendar.nameOf(DateTime(2027, 5, 3)), '노동절 대체공휴일');
      expect(calendar.nameOf(DateTime(2027, 7, 19)), '제헌절 대체공휴일');
    });

    test('부처님 오신 날은 5월 13일', () {
      expect(calendar.nameOf(DateTime(2027, 5, 13)), '부처님 오신 날');
      expect(calendar.nameOf(DateTime(2027, 5, 15)), isNull);
    });

    test('나머지 대체공휴일', () {
      expect(calendar.nameOf(DateTime(2027, 8, 16)), '광복절 대체공휴일');
      expect(calendar.nameOf(DateTime(2027, 10, 4)), '개천절 대체공휴일');
      expect(calendar.nameOf(DateTime(2027, 10, 11)), '한글날 대체공휴일');
      expect(calendar.nameOf(DateTime(2027, 12, 27)), '성탄절 대체공휴일');
    });

    test('모두 24일(조사 표의 행 수)', () {
      final days = koreanHolidays.keys.where((k) => k ~/ 10000 == 2027);
      expect(days, hasLength(24));
    });
  });

  test('평일 · 기념일은 null', () {
    expect(calendar.nameOf(DateTime(2026, 10, 7)), isNull);
    expect(calendar.nameOf(DateTime(2026, 5, 8)), isNull); // 어버이날(기념일)
    expect(calendar.nameOf(DateTime(2026, 10, 1)), isNull); // 국군의 날(기념일)
  });

  test('시각이 있어도 날짜로 본다', () {
    expect(calendar.nameOf(DateTime(2026, 10, 9, 7, 30)), '한글날');
  });

  test('표 밖의 해는 null', () {
    expect(calendar.nameOf(DateTime(2028, 1, 1)), isNull);
  });
}
