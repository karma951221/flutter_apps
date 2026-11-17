import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/transit/entity/transit_point.dart';
import '../../../domain/transit/transit_failure.dart';
import '../../../domain/transit/usecase/find_transit_routes.dart';

part 'transit_state.freezed.dart';

/// 경로 조회 한 번의 진행 상태.
@freezed
sealed class TransitStatus with _$TransitStatus {
  const factory TransitStatus.idle() = TransitIdle;
  const factory TransitStatus.loading() = TransitLoading;
  const factory TransitStatus.loaded(TransitRoutesResult result) =
      TransitLoaded;
  const factory TransitStatus.failure(TransitFailure failure) = TransitFailed;
}

/// 길찾기 탭 상태 — 출발 · 도착 · 현재 위치 찾는 중/실패 · 조회 상태.
@freezed
class TransitState with _$TransitState {
  @override
  final TransitPoint? from;

  @override
  final TransitPoint? to;

  /// 현재 위치를 찾는 중.
  @override
  final bool locating;

  /// 현재 위치를 얻지 못했다. 출발은 비어 있다.
  @override
  final bool locationFailed;

  @override
  final TransitStatus status;

  const TransitState({
    this.from,
    this.to,
    this.locating = false,
    this.locationFailed = false,
    this.status = const TransitStatus.idle(),
  });
}
