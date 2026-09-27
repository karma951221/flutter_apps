import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entity/daily_activity.dart';

part 'today_activity_state.freezed.dart';

@freezed
sealed class TodayActivityState with _$TodayActivityState {
  const factory TodayActivityState.loading() = TodayActivityLoading;

  const factory TodayActivityState.loaded(DailyActivity activity) =
      TodayActivityLoaded;

  const factory TodayActivityState.failure(Failure failure) =
      TodayActivityFailure;
}
