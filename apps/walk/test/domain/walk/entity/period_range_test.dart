import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/walk/entity/period_kind.dart';
import 'package:walk/domain/walk/entity/period_range.dart';

void main() {
  group('주간', () {
    test('수요일이 속한 주는 월요일부터 일요일까지다', () {
      final range = periodRange(PeriodKind.week, 0, DateTime(2026, 9, 23, 15));
      expect(range.start, DateTime(2026, 9, 21));
      expect(range.end, DateTime(2026, 9, 27));
    });

    test('일요일에 열면 그 주 월요일부터다', () {
      final range = periodRange(
        PeriodKind.week,
        0,
        DateTime(2026, 9, 27, 23, 59),
      );
      expect(range.start, DateTime(2026, 9, 21));
    });

    test('offset -1 은 지난 주, 달을 넘어간다', () {
      final range = periodRange(PeriodKind.week, -1, DateTime(2026, 9, 1));
      expect(range.start, DateTime(2026, 8, 24));
      expect(range.end, DateTime(2026, 8, 30));
    });
  });

  group('월간', () {
    test('윤년 2월은 29일까지다', () {
      final range = periodRange(PeriodKind.month, 0, DateTime(2028, 2, 10));
      expect(range.start, DateTime(2028, 2, 1));
      expect(range.end, DateTime(2028, 2, 29));
    });

    test('offset -1 은 연도를 넘어간다', () {
      final range = periodRange(PeriodKind.month, -1, DateTime(2026, 1, 15));
      expect(range.start, DateTime(2025, 12, 1));
      expect(range.end, DateTime(2025, 12, 31));
    });
  });

  test('daysBetween 은 양 끝을 포함한다', () {
    expect(daysBetween(DateTime(2026, 9, 29), DateTime(2026, 10, 2)), [
      DateTime(2026, 9, 29),
      DateTime(2026, 9, 30),
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 2),
    ]);
  });
}
