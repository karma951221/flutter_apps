import 'dart:math' as math;

import '../../walk/entity/walk.dart';
import '../entity/period_range.dart';
import '../entity/period_stats.dart';
import '../entity/period_summary.dart';
import '../entity/stats_bucket.dart';
import '../entity/stats_period.dart';
import '../entity/walk_records.dart';

/// 산책 목록에서 기간 통계와 기록을 계산한다. 상태가 없고 시계를 직접 읽지 않는다.
///
/// 모든 날짜는 현지 시각이고, 산책은 시작 시각의 현지 날짜 하나에만 속한다.
/// 날짜 더하기는 `DateTime(y, m, d + n)` 으로 해서 서머타임이 있어도 자정이 밀리지 않는다.
abstract final class WalkStatsPolicy {
  static PeriodRange periodRange(
    StatsPeriod period,
    DateTime now, {
    int offset = 0,
  }) {
    final local = now.toLocal();
    switch (period) {
      case StatsPeriod.week:
        final start = DateTime(
          local.year,
          local.month,
          local.day - (local.weekday - DateTime.monday) + 7 * offset,
        );
        return PeriodRange(start: start, end: _addDays(start, 7));
      case StatsPeriod.month:
        final start = DateTime(local.year, local.month + offset);
        return PeriodRange(
          start: start,
          end: DateTime(start.year, start.month + 1),
        );
    }
  }

  static PeriodStats periodStats(
    List<Walk> walks,
    StatsPeriod period,
    DateTime now, {
    int offset = 0,
  }) {
    final range = periodRange(period, now, offset: offset);
    return PeriodStats(
      period: period,
      range: range,
      summary: _summarize(walks, range),
      previousSummary: _summarize(
        walks,
        periodRange(period, now, offset: offset - 1),
      ),
      buckets: [
        for (final bucket in _bucketRanges(period, range))
          _bucket(walks, bucket),
      ],
    );
  }

  static WalkRecords records(List<Walk> walks, DateTime now) {
    if (walks.isEmpty) return WalkRecords.empty;

    final days = {for (final walk in walks) _day(walk.startedAt.toLocal())};
    final today = _day(now.toLocal());
    // 오늘 아직 안 걸었으면 어제부터 — 아침에 연속이 0 으로 꺼지지 않게.
    var cursor = days.contains(today) ? today : _addDays(today, -1);
    var current = 0;
    while (days.contains(cursor)) {
      current++;
      cursor = _addDays(cursor, -1);
    }

    final sorted = days.toList()..sort();
    var longestStreak = 0;
    var run = 0;
    DateTime? previous;
    for (final day in sorted) {
      run = previous != null && _addDays(previous, 1) == day ? run + 1 : 1;
      longestStreak = math.max(longestStreak, run);
      previous = day;
    }

    // 최근 것부터 보며 더 클 때만 바꾸면 동률은 최근 것이 남는다.
    final recentFirst = [...walks]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    Walk? farthest;
    Walk? longest;
    for (final walk in recentFirst) {
      if (farthest == null || walk.distanceMeters > farthest.distanceMeters) {
        farthest = walk;
      }
      if (longest == null || walk.duration > longest.duration) {
        longest = walk;
      }
    }

    return WalkRecords(
      currentStreakDays: current,
      longestStreakDays: longestStreak,
      farthest: farthest,
      longest: longest,
    );
  }

  /// 가장 오래된 산책이 든 기간의 offset. 산책이 없거나 모두 미래면 0.
  static int earliestOffset(
    List<Walk> walks,
    StatsPeriod period,
    DateTime now,
  ) {
    if (walks.isEmpty) return 0;
    final earliest = walks
        .map((walk) => walk.startedAt.toLocal())
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final current = periodRange(period, now).start;
    final target = periodRange(period, earliest).start;
    final offset = switch (period) {
      StatsPeriod.week => -(_daysBetween(target, current) ~/ 7),
      StatsPeriod.month =>
        (target.year - current.year) * 12 + target.month - current.month,
    };
    return math.min(0, offset);
  }

  static List<PeriodRange> _bucketRanges(
    StatsPeriod period,
    PeriodRange range,
  ) {
    switch (period) {
      case StatsPeriod.week:
        return [
          for (var i = 0; i < 7; i++)
            PeriodRange(
              start: _addDays(range.start, i),
              end: _addDays(range.start, i + 1),
            ),
        ];
      case StatsPeriod.month:
        final buckets = <PeriodRange>[];
        var start = range.start;
        while (start.isBefore(range.end)) {
          // 다음 월요일까지. 월요일(1)이면 7일, 일요일(7)이면 1일.
          var end = _addDays(start, 8 - start.weekday);
          if (end.isAfter(range.end)) end = range.end;
          buckets.add(PeriodRange(start: start, end: end));
          start = end;
        }
        return buckets;
    }
  }

  static PeriodSummary _summarize(List<Walk> walks, PeriodRange range) {
    var distance = 0.0;
    var duration = Duration.zero;
    var count = 0;
    for (final walk in walks) {
      if (!range.contains(walk.startedAt.toLocal())) continue;
      distance += walk.distanceMeters;
      duration += walk.duration;
      count++;
    }
    return PeriodSummary(
      distanceMeters: distance,
      duration: duration,
      walkCount: count,
    );
  }

  static StatsBucket _bucket(List<Walk> walks, PeriodRange range) {
    final summary = _summarize(walks, range);
    return StatsBucket(
      range: range,
      distanceMeters: summary.distanceMeters,
      walkCount: summary.walkCount,
    );
  }

  static DateTime _day(DateTime local) =>
      DateTime(local.year, local.month, local.day);

  static DateTime _addDays(DateTime day, int days) =>
      DateTime(day.year, day.month, day.day + days);

  /// 서머타임과 무관한 날짜 차이.
  static int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}
