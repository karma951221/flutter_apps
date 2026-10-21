import 'package:intl/intl.dart';

/// 숫자 · 날짜 표기를 한곳에 둔다.
abstract final class WalkFormat {
  static String steps(String locale, int steps) =>
      NumberFormat.decimalPattern(locale).format(steps);

  static String weekRange(String locale, DateTime start, DateTime end) {
    final format = DateFormat.MMMd(locale);
    return '${format.format(start)} – ${format.format(end)}';
  }

  static String month(String locale, DateTime start) =>
      DateFormat.yMMMM(locale).format(start);

  static String weekday(String locale, DateTime day) =>
      DateFormat.E(locale).format(day);

  static String day(DateTime day) => '${day.day}';
}
