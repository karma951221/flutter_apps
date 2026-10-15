import 'package:freezed_annotation/freezed_annotation.dart';

import 'period_range.dart';
import 'period_summary.dart';
import 'stats_bucket.dart';
import 'stats_period.dart';

part 'period_stats.freezed.dart';

/// 한 기간의 통계. [previousSummary] 는 바로 전 같은 종류 기간 전체의 합이다.
@freezed
class PeriodStats with _$PeriodStats {
  @override
  final StatsPeriod period;
  @override
  final PeriodRange range;
  @override
  final PeriodSummary summary;
  @override
  final PeriodSummary previousSummary;
  @override
  final List<StatsBucket> buckets;

  const PeriodStats({
    required this.period,
    required this.range,
    required this.summary,
    required this.previousSummary,
    required this.buckets,
  });
}
