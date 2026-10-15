import 'package:freezed_annotation/freezed_annotation.dart';

part 'period_range.freezed.dart';

/// 현지 시각의 반열린 구간 `[start, end)`.
@freezed
class PeriodRange with _$PeriodRange {
  @override
  final DateTime start;
  @override
  final DateTime end;

  const PeriodRange({required this.start, required this.end});

  /// [local] 은 현지 시각이어야 한다.
  bool contains(DateTime local) =>
      !local.isBefore(start) && local.isBefore(end);
}
