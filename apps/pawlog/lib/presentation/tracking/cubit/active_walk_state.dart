import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/dog/entity/dog.dart';
import '../../../domain/tracking/entity/walk_session.dart';

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

  /// [locationError] 가 있으면 위치를 못 받고 있다 — 기록은 이어 가며 다시 받기를 권한다.
  const factory ActiveWalkState.tracking({
    required WalkSession session,
    required Duration elapsed,
    Failure? locationError,
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
