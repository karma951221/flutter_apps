import 'package:freezed_annotation/freezed_annotation.dart';

import '../../diary/entity/story.dart';

part 'map_period.freezed.dart';

/// 지도가 보여 줄 기간.
@freezed
sealed class MapPeriod with _$MapPeriod {
  const factory MapPeriod.day(DateTime date) = DayPeriod;
  const factory MapPeriod.month(int year, int month) = MonthPeriod;
  const factory MapPeriod.story(Story story) = StoryPeriod;
}

extension MapPeriodBounds on MapPeriod {
  /// 현지 시각, 양 끝 포함. 끝나지 않은 스토리는 [now] 까지.
  ({DateTime from, DateTime to}) bounds(DateTime now) => switch (this) {
    DayPeriod(:final date) => (
      from: DateTime(date.year, date.month, date.day),
      to: DateTime(date.year, date.month, date.day, 23, 59, 59, 999),
    ),
    MonthPeriod(:final year, :final month) => (
      from: DateTime(year, month),
      to: DateTime(year, month + 1).subtract(const Duration(milliseconds: 1)),
    ),
    StoryPeriod(:final story) => (
      from: story.startedAt.toLocal(),
      to: story.endedAt?.toLocal() ?? now,
    ),
  };
}
