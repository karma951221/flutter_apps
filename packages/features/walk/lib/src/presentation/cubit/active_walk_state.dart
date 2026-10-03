import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entity/dog.dart';
import '../../domain/entity/walk_session.dart';

part 'active_walk_state.freezed.dart';

@freezed
sealed class ActiveWalkState with _$ActiveWalkState {
  /// `load()` 가 추적기 상태와 반려견을 읽는 동안.
  const factory ActiveWalkState.loading() = ActiveWalkLoading;

  /// 반려견을 고르는 시작 전 화면. [dogs] 가 비면 등록 안내를 보인다.
  const factory ActiveWalkState.selectingDogs({
    required List<Dog> dogs,
    required Set<String> selectedIds,
  }) = ActiveWalkSelectingDogs;

  const factory ActiveWalkState.starting({
    required List<Dog> dogs,
    required Set<String> selectedIds,
  }) = ActiveWalkStarting;

  const factory ActiveWalkState.tracking({
    required WalkSession session,
    required Duration elapsed,
  }) = ActiveWalkTracking;

  const factory ActiveWalkState.stopped(WalkSession session) =
      ActiveWalkStopped;

  /// [selectedIds] 가 비어 있으면 `load()` 단계의 실패다(재시도 = 다시 읽기).
  const factory ActiveWalkState.failure({
    required Failure failure,
    required List<Dog> dogs,
    required Set<String> selectedIds,
  }) = ActiveWalkFailure;
}
