import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/walk/entity/activity_period.dart';

part 'period_activity_state.freezed.dart';

@freezed
sealed class PeriodActivityState with _$PeriodActivityState {
  const factory PeriodActivityState.loading(int offset) = PeriodActivityLoading;

  const factory PeriodActivityState.loaded(int offset, ActivityPeriod period) =
      PeriodActivityLoaded;

  const factory PeriodActivityState.failure(int offset, Failure failure) =
      PeriodActivityFailure;
}
