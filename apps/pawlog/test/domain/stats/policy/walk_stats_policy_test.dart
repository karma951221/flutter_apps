import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/domain/stats/entity/period_range.dart';
import 'package:pawlog/domain/stats/entity/stats_period.dart';
import 'package:pawlog/domain/stats/entity/walk_records.dart';
import 'package:pawlog/domain/stats/policy/walk_stats_policy.dart';
import 'package:pawlog/domain/walk/entity/walk.dart';

import '../../../support/fakes.dart';

Walk _walk(
  String id,
  DateTime startedAt, {
  double meters = 1000,
  Duration duration = const Duration(minutes: 30),
}) => Walk(
  id: id,
  startedAt: startedAt,
  endedAt: startedAt.add(duration),
  duration: duration,
  distanceMeters: meters,
  dogs: [dog('1')],
  photos: const [],
  previewPoints: const [],
  createdAt: startedAt,
  updatedAt: startedAt,
);

PeriodRange _range(DateTime start, DateTime end) =>
    PeriodRange(start: start, end: end);

void main() {
  // 2026-10-16 은 금요일. 그 주는 10-12(월) ~ 10-18(일).
  final now = DateTime(2026, 10, 16, 15);

  group('periodRange', () {
    test('주는 월요일 00:00 부터 7일이다', () {
      expect(
        WalkStatsPolicy.periodRange(StatsPeriod.week, now),
        _range(DateTime(2026, 10, 12), DateTime(2026, 10, 19)),
      );
    });

    test('일요일 23:59 는 같은 주, 월요일 00:00 은 다음 주다', () {
      expect(
        WalkStatsPolicy.periodRange(
          StatsPeriod.week,
          DateTime(2026, 10, 18, 23, 59),
        ).start,
        DateTime(2026, 10, 12),
      );
      expect(
        WalkStatsPolicy.periodRange(
          StatsPeriod.week,
          DateTime(2026, 10, 19),
        ).start,
        DateTime(2026, 10, 19),
      );
    });

    test('offset -1 은 바로 전 주다', () {
      expect(
        WalkStatsPolicy.periodRange(StatsPeriod.week, now, offset: -1),
        _range(DateTime(2026, 10, 5), DateTime(2026, 10, 12)),
      );
    });

    test('연말 · 연초를 걸친 주', () {
      expect(
        WalkStatsPolicy.periodRange(StatsPeriod.week, DateTime(2027, 1, 1, 8)),
        _range(DateTime(2026, 12, 28), DateTime(2027, 1, 4)),
      );
    });

    test('월은 1일부터 다음 달 1일 전까지, offset 은 해를 넘는다', () {
      expect(
        WalkStatsPolicy.periodRange(StatsPeriod.month, now),
        _range(DateTime(2026, 10), DateTime(2026, 11)),
      );
      expect(
        WalkStatsPolicy.periodRange(StatsPeriod.month, now, offset: -10),
        _range(DateTime(2025, 12), DateTime(2026, 1)),
      );
    });
  });

  group('periodStats', () {
    final walks = [
      _walk(
        'b',
        DateTime(2026, 10, 16, 8),
        meters: 2500,
        duration: const Duration(minutes: 45),
      ),
      _walk('a', DateTime(2026, 10, 12, 7)),
      _walk(
        'p',
        DateTime(2026, 10, 5, 7),
        meters: 800,
        duration: const Duration(minutes: 20),
      ),
    ];

    test('이번 주 합과 지난주 전체 합', () {
      final stats = WalkStatsPolicy.periodStats(walks, StatsPeriod.week, now);

      expect(stats.period, StatsPeriod.week);
      expect(stats.summary.distanceMeters, 3500);
      expect(stats.summary.duration, const Duration(minutes: 75));
      expect(stats.summary.walkCount, 2);
      expect(stats.previousSummary.distanceMeters, 800);
      expect(stats.previousSummary.walkCount, 1);
    });

    test('주 보기는 월 ~ 일 7칸이다', () {
      final stats = WalkStatsPolicy.periodStats(walks, StatsPeriod.week, now);

      expect(stats.buckets, hasLength(7));
      expect(stats.buckets.first.range.start, DateTime(2026, 10, 12));
      expect(stats.buckets.first.distanceMeters, 1000);
      expect(stats.buckets[4].distanceMeters, 2500); // 금요일
      expect(stats.buckets[1].distanceMeters, 0);
    });

    test('자정을 넘긴 산책은 시작한 날에만 들어간다', () {
      final late = [
        _walk(
          'n',
          DateTime(2026, 10, 18, 23, 50),
          duration: const Duration(minutes: 40),
        ),
      ];

      final thisWeek = WalkStatsPolicy.periodStats(late, StatsPeriod.week, now);
      final nextWeek = WalkStatsPolicy.periodStats(
        late,
        StatsPeriod.week,
        DateTime(2026, 10, 19, 9),
      );

      expect(thisWeek.buckets[6].walkCount, 1);
      expect(nextWeek.summary.walkCount, 0);
    });

    test('UTC 로 들어온 시작 시각도 현지 날짜 칸에 들어간다', () {
      final utc = [_walk('u', DateTime(2026, 10, 12, 0, 30).toUtc())];

      final stats = WalkStatsPolicy.periodStats(utc, StatsPeriod.week, now);

      expect(stats.buckets.first.walkCount, 1);
    });

    test('월 보기는 월요일 시작 주마다 한 칸, 첫 · 끝 칸은 달로 자른다', () {
      final october = WalkStatsPolicy.periodStats(
        const [],
        StatsPeriod.month,
        now,
      );

      expect(
        [for (final b in october.buckets) b.range.start.day],
        [1, 5, 12, 19, 26],
      );
      expect(october.buckets.last.range.end, DateTime(2026, 11));
      // 2027-02-01 은 월요일, 28일 → 4칸. 2026-11-01 은 일요일, 30일 → 6칸.
      expect(
        WalkStatsPolicy.periodStats(
          const [],
          StatsPeriod.month,
          DateTime(2027, 2, 10),
        ).buckets,
        hasLength(4),
      );
      expect(
        WalkStatsPolicy.periodStats(
          const [],
          StatsPeriod.month,
          DateTime(2026, 11, 10),
        ).buckets,
        hasLength(6),
      );
    });

    test('월 칸에 거리가 합쳐진다', () {
      final stats = WalkStatsPolicy.periodStats(walks, StatsPeriod.month, now);

      expect(stats.summary.distanceMeters, 4300);
      expect(stats.buckets[1].distanceMeters, 800); // 5–11
      expect(stats.buckets[2].distanceMeters, 3500); // 12–18
    });
  });

  group('records', () {
    test('산책이 없으면 비어 있다', () {
      expect(WalkStatsPolicy.records(const [], now), WalkRecords.empty);
    });

    test('오늘까지 이어진 연속 일수', () {
      final walks = [
        _walk('c', DateTime(2026, 10, 16, 7)),
        _walk('b', DateTime(2026, 10, 15, 7)),
        _walk('a', DateTime(2026, 10, 14, 7)),
      ];

      expect(WalkStatsPolicy.records(walks, now).currentStreakDays, 3);
    });

    test('오늘 아직 산책이 없으면 어제부터 센다', () {
      final walks = [
        _walk('b', DateTime(2026, 10, 15, 7)),
        _walk('a', DateTime(2026, 10, 14, 7)),
      ];

      expect(WalkStatsPolicy.records(walks, now).currentStreakDays, 2);
    });

    test('어제도 없으면 0 이다', () {
      final walks = [_walk('a', DateTime(2026, 10, 13, 7))];

      expect(WalkStatsPolicy.records(walks, now).currentStreakDays, 0);
    });

    test('최장 연속은 하루 여러 건을 하루로 센다', () {
      final walks = [
        _walk('e', DateTime(2026, 10, 10, 7)),
        _walk('d', DateTime(2026, 10, 3, 18)),
        _walk('c', DateTime(2026, 10, 3, 7)),
        _walk('b', DateTime(2026, 10, 2, 7)),
        _walk('a', DateTime(2026, 10, 1, 7)),
      ];

      expect(WalkStatsPolicy.records(walks, now).longestStreakDays, 3);
    });

    test('가장 먼 · 가장 오래 걸은 산책, 같으면 최근 것', () {
      final older = _walk('old', DateTime(2026, 10, 1, 7), meters: 3000);
      final newer = _walk('new', DateTime(2026, 10, 9, 7), meters: 3000);
      final long = _walk(
        'long',
        DateTime(2026, 10, 2, 7),
        meters: 500,
        duration: const Duration(hours: 2),
      );

      // 피드 순서가 아니어도 최근 것을 고른다.
      final records = WalkStatsPolicy.records([older, long, newer], now);

      expect(records.farthest?.id, 'new');
      expect(records.longest?.id, 'long');
    });
  });

  group('earliestOffset', () {
    final walks = [
      _walk('b', DateTime(2026, 10, 16, 7)),
      _walk('a', DateTime(2026, 9, 30, 7)), // 9-28 주, 9월
    ];

    test('가장 오래된 산책이 든 기간까지', () {
      expect(WalkStatsPolicy.earliestOffset(walks, StatsPeriod.week, now), -2);
      expect(WalkStatsPolicy.earliestOffset(walks, StatsPeriod.month, now), -1);
    });

    test('산책이 없으면 0', () {
      expect(
        WalkStatsPolicy.earliestOffset(const [], StatsPeriod.week, now),
        0,
      );
    });

    test('시계가 틀어져 미래 산책만 있어도 0 보다 크지 않다', () {
      final future = [_walk('f', DateTime(2026, 11, 20, 7))];

      expect(WalkStatsPolicy.earliestOffset(future, StatsPeriod.week, now), 0);
      expect(WalkStatsPolicy.earliestOffset(future, StatsPeriod.month, now), 0);
    });
  });
}
