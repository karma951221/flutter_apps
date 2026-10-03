import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entity/walk.dart';
import '../../domain/entity/walk_track_point.dart';

part 'walk_detail_state.freezed.dart';

@freezed
sealed class WalkDetailState with _$WalkDetailState {
  const factory WalkDetailState.loading() = WalkDetailLoading;

  /// [failure] 는 삭제 실패 — 화면이 비지 않게 내용을 그대로 둔다.
  const factory WalkDetailState.loaded({
    required Walk walk,
    required List<WalkTrackPoint> track,
    Failure? failure,
  }) = WalkDetailLoaded;

  const factory WalkDetailState.deleting({
    required Walk walk,
    required List<WalkTrackPoint> track,
  }) = WalkDetailDeleting;

  const factory WalkDetailState.deleted() = WalkDetailDeleted;

  const factory WalkDetailState.failure(Failure failure) = WalkDetailFailure;
}
