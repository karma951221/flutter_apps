import 'package:freezed_annotation/freezed_annotation.dart';

part 'period_summary.freezed.dart';

/// 한 기간에 시작한 산책들의 합.
@freezed
class PeriodSummary with _$PeriodSummary {
  @override
  final double distanceMeters;
  @override
  final Duration duration;
  @override
  final int walkCount;

  const PeriodSummary({
    required this.distanceMeters,
    required this.duration,
    required this.walkCount,
  });

  static const empty = PeriodSummary(
    distanceMeters: 0,
    duration: Duration.zero,
    walkCount: 0,
  );
}
