import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_activity.freezed.dart';

/// 하루 합계. 거리 · 칼로리는 Health Connect 에 기록이 없으면 null — 계산하지 않는다.
@freezed
class DailyActivity with _$DailyActivity {
  /// 그날 자정(로컬).
  @override
  final DateTime date;
  @override
  final int steps;
  @override
  final double? distanceMeters;
  @override
  final double? activeKcal;

  const DailyActivity({
    required this.date,
    required this.steps,
    this.distanceMeters,
    this.activeKcal,
  });

  /// 기록 없는 날. (Freezed 가 factory 를 union 으로 오해하지 않게 static 으로 둔다.)
  static DailyActivity empty(DateTime date) => DailyActivity(date: date, steps: 0);
}
