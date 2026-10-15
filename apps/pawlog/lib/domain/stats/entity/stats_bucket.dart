import 'package:freezed_annotation/freezed_annotation.dart';

import 'period_range.dart';

part 'stats_bucket.freezed.dart';

/// 막대 그래프의 한 칸 — 주 보기는 하루, 월 보기는 그 달 안의 한 주.
@freezed
class StatsBucket with _$StatsBucket {
  @override
  final PeriodRange range;
  @override
  final double distanceMeters;
  @override
  final int walkCount;

  const StatsBucket({
    required this.range,
    required this.distanceMeters,
    required this.walkCount,
  });
}
