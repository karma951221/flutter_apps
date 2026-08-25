import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';

part 'block_action_state.freezed.dart';

/// 차단 동작 하나(진행 중 여부 · 실패)의 상태.
///
/// [ReportState](../cubit/report_state.dart)와 같은 모양이다 — 시트/다이얼로그
/// 하나의 진행 상태만 담고, 목록 반영은 호출한 화면이 각자 소유한 목록
/// (`FeedCubit`)에 한다.
@freezed
class BlockActionState with _$BlockActionState {
  const BlockActionState({this.isBlocking = false, this.failure});

  @override
  final bool isBlocking;

  @override
  final Failure? failure;
}
