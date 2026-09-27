import 'package:intl/intl.dart';

/// 숫자 · 날짜 표기를 한곳에 둔다. 값이 없으면 [missing] — 계산해서 채우지 않는다.
abstract final class WalkFormat {
  static const missing = '–';

  static String steps(String locale, int steps) =>
      NumberFormat.decimalPattern(locale).format(steps);

  static String distance(String locale, double? meters) => meters == null
      ? missing
      : '${NumberFormat('0.0', locale).format(meters / 1000)} km';

  static String kcal(String locale, double? kcal) => kcal == null
      ? missing
      : '${NumberFormat.decimalPattern(locale).format(kcal.round())} kcal';

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
