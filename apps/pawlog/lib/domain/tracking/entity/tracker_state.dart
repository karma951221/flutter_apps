import 'package:freezed_annotation/freezed_annotation.dart';

import 'walk_session.dart';

part 'tracker_state.freezed.dart';

@freezed
sealed class TrackerState with _$TrackerState {
  const factory TrackerState.idle() = TrackerIdle;
  const factory TrackerState.tracking(WalkSession session) = TrackerTracking;
  const factory TrackerState.finished(WalkSession session) = TrackerFinished;
}
