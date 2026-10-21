import 'package:freezed_annotation/freezed_annotation.dart';

import 'daily_activity.dart';
import 'period_kind.dart';

part 'activity_period.freezed.dart';

@freezed
class ActivityPeriod with _$ActivityPeriod {
  @override
  final PeriodKind kind;
  @override
  final DateTime start;

  /// 마지막 날(포함).
  @override
  final DateTime end;

  /// 계산 기준일(자정). 일평균 · 강조 · 다음 버튼이 이것을 본다.
  @override
  final DateTime today;

  /// [start]..[end] 모든 날. 기록이 없거나 오늘 이후인 날은 0보.
  @override
  final List<DailyActivity> days;

  const ActivityPeriod({
    required this.kind,
    required this.start,
    required this.end,
    required this.today,
    required this.days,
  });

  int get totalSteps => days.fold(0, (sum, day) => sum + day.steps);

  int get averageSteps {
    final elapsed = days.where((day) => !day.date.isAfter(today)).toList();
    if (elapsed.isEmpty) return 0;
    return (elapsed.fold(0, (sum, day) => sum + day.steps) / elapsed.length)
        .round();
  }

  double? get totalDistanceMeters =>
      _sumPresent(days.map((d) => d.distanceMeters));

  double? get totalActiveKcal => _sumPresent(days.map((d) => d.activeKcal));

  bool get isCurrent => !today.isBefore(start) && !today.isAfter(end);

  static double? _sumPresent(Iterable<double?> values) {
    final present = values.whereType<double>();
    if (present.isEmpty) return null;
    return present.fold<double>(0, (sum, v) => sum + v);
  }
}
