import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'walk_session.dart';

part 'tracker_state.freezed.dart';

@freezed
sealed class TrackerState with _$TrackerState {
  const factory TrackerState.idle() = TrackerIdle;

  /// [locationError] 는 위치 스트림이 낸 마지막 오류다. 산책은 끊지 않고 이어 가며,
  /// 다음 위치가 들어오거나 `resume` 이 성공하면 지운다.
  const factory TrackerState.tracking(
    WalkSession session, {
    Failure? locationError,
  }) = TrackerTracking;
  const factory TrackerState.finished(WalkSession session) = TrackerFinished;
}
