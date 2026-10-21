import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_activity.freezed.dart';

/// 하루 걸음 합계. 거리 · 칼로리는 폰에 기록이 없는 경우가 많아 읽지 않는다(2026-10-21 QA).
@freezed
class DailyActivity with _$DailyActivity {
  /// 그날 자정(로컬).
  @override
  final DateTime date;
  @override
  final int steps;
  const DailyActivity({required this.date, required this.steps});

  /// 기록 없는 날. (Freezed 가 factory 를 union 으로 오해하지 않게 static 으로 둔다.)
  static DailyActivity empty(DateTime date) =>
      DailyActivity(date: date, steps: 0);
}
