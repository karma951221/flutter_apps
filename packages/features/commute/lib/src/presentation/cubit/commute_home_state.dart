import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';
import '../../domain/entity/commute_direction.dart';
import '../../domain/entity/commute_result.dart';

part 'commute_home_state.freezed.dart';

@freezed
sealed class CommuteHomeState with _$CommuteHomeState {
  const factory CommuteHomeState.initial(CommuteDirection direction) =
      CommuteHomeInitial;

  const factory CommuteHomeState.loading(CommuteDirection direction) =
      CommuteHomeLoading;

  const factory CommuteHomeState.loaded(
    CommuteDirection direction,
    CommuteResult result,
  ) = CommuteHomeLoaded;

  const factory CommuteHomeState.failure(
    CommuteDirection direction,
    Failure failure,
  ) = CommuteHomeFailure;
}
