import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';

part 'block_action_state.freezed.dart';

/// 차단 동작과 프로필 메뉴용 차단 상태의 상태.
///
/// [ReportState](../cubit/report_state.dart)와 같은 모양이다 — 시트/다이얼로그
/// 하나의 진행 상태만 담고, 목록 반영은 호출한 화면이 각자 소유한 목록
/// (`FeedCubit`)에 한다.
@freezed
class BlockActionState with _$BlockActionState {
  const BlockActionState({
    this.isBlocking = false,
    this.isLoadingStatus = false,
    this.isBlocked,
    this.failure,
  });

  @override
  final bool isBlocking;

  /// `null` 은 아직 확인하지 않았거나 확인에 실패한 상태다. `false` 와
  /// 구분해야 이미 차단한 사용자에게 잘못 '차단'을 권하지 않는다.
  @override
  final bool? isBlocked;

  @override
  final bool isLoadingStatus;

  @override
  final Failure? failure;
}
