import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/stats/entity/period_range.dart';
import '../../../domain/stats/entity/period_stats.dart';
import '../../../domain/stats/entity/stats_period.dart';
import '../../walk/format/walk_format.dart';

/// 통계 화면의 기간 · 칸 라벨과 비교 문구. 위젯 없이 로케일만 받는 순수 함수다.
abstract final class StatsFormat {
  /// 주: `10월 12일 – 18일`, 달이 걸치면 `9월 28일 – 10월 4일`, 올해가 아니면 연도를 붙인다.
  /// 월: `2026년 10월`.
  static String rangeLabel(
    String locale,
    StatsPeriod period,
    PeriodRange range,
    DateTime now,
  ) {
    switch (period) {
      case StatsPeriod.month:
        return DateFormat.yMMMM(locale).format(range.start);
      case StatsPeriod.week:
        final first = range.start;
        final last = _lastDay(range);
        final thisYear = first.year == now.year && last.year == now.year;
        final full = thisYear
            ? DateFormat.MMMd(locale)
            : DateFormat.yMMMd(locale);
        final sameMonth = first.year == last.year && first.month == last.month;
        final end = sameMonth && thisYear ? DateFormat.d(locale) : full;
        return '${full.format(first)} – ${end.format(last)}';
    }
  }

  /// 주 보기는 요일(`월`), 월 보기는 일 범위(`26–31`, 하루면 `1`).
  static String bucketLabel(
    String locale,
    StatsPeriod period,
    PeriodRange range,
  ) {
    switch (period) {
      case StatsPeriod.week:
        return DateFormat.E(locale).format(range.start);
      case StatsPeriod.month:
        final first = range.start.day;
        final last = _lastDay(range).day;
        return first == last ? '$first' : '$first–$last';
    }
  }

  /// 지난 기간 거리가 0 이면 null. 이번이 더 길면 차이를, 아니면 지난 기간 합만 말한다 —
  /// 주 초반에 '덜 걸었어요' 를 보이지 않으려는 것.
  static String? comparison(AppLocalizations l10n, PeriodStats stats) {
    final previous = stats.previousSummary.distanceMeters;
    if (previous <= 0) return null;
    final current = stats.summary.distanceMeters;
    final isWeek = stats.period == StatsPeriod.week;
    if (current > previous) {
      final diff = WalkFormat.distance(l10n, current - previous);
      return isWeek
          ? l10n.walkStatsMoreThanLastWeek(diff)
          : l10n.walkStatsMoreThanLastMonth(diff);
    }
    final total = WalkFormat.distance(l10n, previous);
    return isWeek ? l10n.walkStatsLastWeek(total) : l10n.walkStatsLastMonth(total);
  }

  static DateTime _lastDay(PeriodRange range) =>
      DateTime(range.end.year, range.end.month, range.end.day - 1);
}
