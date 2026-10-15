import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:l10n/l10n.dart';
import 'package:pawlog/domain/stats/entity/period_range.dart';
import 'package:pawlog/domain/stats/entity/period_stats.dart';
import 'package:pawlog/domain/stats/entity/period_summary.dart';
import 'package:pawlog/domain/stats/entity/stats_period.dart';
import 'package:pawlog/presentation/stats/format/stats_format.dart';

PeriodSummary _km(double meters) => PeriodSummary(
  distanceMeters: meters,
  duration: Duration.zero,
  walkCount: meters == 0 ? 0 : 1,
);

PeriodStats _stats(StatsPeriod period, double current, double previous) =>
    PeriodStats(
      period: period,
      range: PeriodRange(start: DateTime(2026, 10, 12), end: DateTime(2026, 10, 19)),
      summary: _km(current),
      previousSummary: _km(previous),
      buckets: const [],
    );

void main() {
  setUpAll(() => initializeDateFormatting('ko'));
  final l10n = lookupAppLocalizations(const Locale('ko'));
  final now = DateTime(2026, 10, 16);

  group('rangeLabel', () {
    test('같은 달 주', () {
      expect(
        StatsFormat.rangeLabel(
          'ko',
          StatsPeriod.week,
          PeriodRange(start: DateTime(2026, 10, 12), end: DateTime(2026, 10, 19)),
          now,
        ),
        '10월 12일 – 18일',
      );
    });

    test('달이 걸친 주', () {
      expect(
        StatsFormat.rangeLabel(
          'ko',
          StatsPeriod.week,
          PeriodRange(start: DateTime(2026, 9, 28), end: DateTime(2026, 10, 5)),
          now,
        ),
        '9월 28일 – 10월 4일',
      );
    });

    test('올해가 아닌 주는 연도를 붙인다', () {
      expect(
        StatsFormat.rangeLabel(
          'ko',
          StatsPeriod.week,
          PeriodRange(start: DateTime(2026, 12, 28), end: DateTime(2027, 1, 4)),
          now,
        ),
        '2026년 12월 28일 – 2027년 1월 3일',
      );
    });

    test('월', () {
      expect(
        StatsFormat.rangeLabel(
          'ko',
          StatsPeriod.month,
          PeriodRange(start: DateTime(2026, 10), end: DateTime(2026, 11)),
          now,
        ),
        '2026년 10월',
      );
    });
  });

  test('bucketLabel — 주는 요일, 월은 일 범위', () {
    expect(
      StatsFormat.bucketLabel(
        'ko',
        StatsPeriod.week,
        PeriodRange(start: DateTime(2026, 10, 12), end: DateTime(2026, 10, 13)),
      ),
      '월',
    );
    expect(
      StatsFormat.bucketLabel(
        'ko',
        StatsPeriod.month,
        PeriodRange(start: DateTime(2026, 10, 26), end: DateTime(2026, 11)),
      ),
      '26–31',
    );
    expect(
      StatsFormat.bucketLabel(
        'ko',
        StatsPeriod.month,
        PeriodRange(start: DateTime(2026, 11, 1), end: DateTime(2026, 11, 2)),
      ),
      '1',
    );
  });

  group('comparison', () {
    test('지난 기간이 0 이면 숨긴다', () {
      expect(StatsFormat.comparison(l10n, _stats(StatsPeriod.week, 3500, 0)), isNull);
    });

    test('더 걸었으면 차이를 말한다', () {
      expect(
        StatsFormat.comparison(l10n, _stats(StatsPeriod.week, 3500, 800)),
        '지난주보다 2.7 km 더 걸었어요',
      );
      expect(
        StatsFormat.comparison(l10n, _stats(StatsPeriod.month, 3500, 800)),
        '지난달보다 2.7 km 더 걸었어요',
      );
    });

    test('같거나 덜 걸었으면 지난 기간 합만 말한다', () {
      expect(
        StatsFormat.comparison(l10n, _stats(StatsPeriod.week, 500, 8400)),
        '지난주 8.4 km',
      );
      expect(
        StatsFormat.comparison(l10n, _stats(StatsPeriod.month, 800, 800)),
        '지난달 800 m',
      );
    });
  });
}
