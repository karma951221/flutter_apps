import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/commute/commute_failure.dart';
import '../../../domain/commute/entity/commute_direction.dart';
import '../../../domain/commute/entity/commute_result.dart';
import '../../../domain/commute/entity/place.dart';

part 'commute_state.freezed.dart';

/// 조회 한 번의 진행 상태.
@freezed
sealed class CommuteStatus with _$CommuteStatus {
  const factory CommuteStatus.idle() = CommuteIdle;
  const factory CommuteStatus.loading() = CommuteLoading;
  const factory CommuteStatus.loaded(CommuteResult result) = CommuteLoaded;
  const factory CommuteStatus.failure(CommuteFailure failure) = CommuteFailed;
}

/// 통근 탭 화면 상태 — 방향 · 집 · 회사 · 조회 상태.
@freezed
class CommuteState with _$CommuteState {
  @override
  final CommuteDirection direction;

  @override
  final Place? home;

  @override
  final Place? work;

  @override
  final CommuteStatus status;

  /// 현재 위치를 찾는 중.
  @override
  final bool locating;

  const CommuteState({
    required this.direction,
    this.home,
    this.work,
    this.status = const CommuteStatus.idle(),
    this.locating = false,
  });
}
