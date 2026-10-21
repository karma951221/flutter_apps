import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/walk/entity/activity_period.dart';
import 'package:walk/domain/walk/entity/daily_activity.dart';
import 'package:walk/domain/walk/entity/period_kind.dart';

ActivityPeriod _week(List<DailyActivity> days, {DateTime? today}) =>
    ActivityPeriod(
      kind: PeriodKind.week,
      start: DateTime(2026, 9, 21),
      end: DateTime(2026, 9, 27),
      today: today ?? DateTime(2026, 9, 23),
      days: days,
    );

void main() {
  final days = [
    DailyActivity(date: DateTime(2026, 9, 21), steps: 1000, distanceMeters: 700),
    DailyActivity(date: DateTime(2026, 9, 22), steps: 2000),
    DailyActivity(date: DateTime(2026, 9, 23), steps: 3001, activeKcal: 120),
    for (var d = 24; d <= 27; d++) DailyActivity.empty(DateTime(2026, 9, d)),
  ];

  test('합계는 모든 날의 걸음을 더한다', () {
    expect(_week(days).totalSteps, 6001);
  });

  test('일평균은 오늘까지 지난 날 수로 나누고 반올림한다', () {
    expect(_week(days).averageSteps, 2000); // 6001 / 3
  });

  test('거리 · 칼로리는 값이 있는 날만 더한다', () {
    expect(_week(days).totalDistanceMeters, 700);
    expect(_week(days).totalActiveKcal, 120);
  });

  test('값이 있는 날이 없으면 null', () {
    final empty = [for (var d = 21; d <= 27; d++) DailyActivity.empty(DateTime(2026, 9, d))];
    expect(_week(empty).totalDistanceMeters, isNull);
    expect(_week(empty).totalActiveKcal, isNull);
  });

  test('오늘이 기간 안이면 isCurrent', () {
    expect(_week(days).isCurrent, isTrue);
    expect(_week(days, today: DateTime(2026, 9, 28)).isCurrent, isFalse);
  });

  test('지난 기간은 7일 전부로 나눈다', () {
    expect(_week(days, today: DateTime(2026, 10, 5)).averageSteps, 857); // 6001 / 7
  });
}
