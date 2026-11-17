import 'period_kind.dart';

typedef PeriodRange = ({DateTime start, DateTime end});

DateTime dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

/// [offset] 0 = [now] 가 속한 기간, -1 = 그 전 기간. 주는 월요일에 시작한다.
/// `end` 는 기간의 마지막 날(포함).
PeriodRange periodRange(PeriodKind kind, int offset, DateTime now) {
  final today = dateOnly(now);
  switch (kind) {
    case PeriodKind.week:
      final start = DateTime(
        today.year,
        today.month,
        today.day - (today.weekday - DateTime.monday) + 7 * offset,
      );
      return (start: start, end: DateTime(start.year, start.month, start.day + 6));
    case PeriodKind.month:
      final start = DateTime(today.year, today.month + offset);
      return (start: start, end: DateTime(start.year, start.month + 1, 0));
  }
}

List<DateTime> daysBetween(DateTime start, DateTime end) => [
  for (
    var day = dateOnly(start);
    !day.isAfter(end);
    day = DateTime(day.year, day.month, day.day + 1)
  )
    day,
];
