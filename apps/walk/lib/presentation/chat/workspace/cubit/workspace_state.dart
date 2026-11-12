import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/chat/workspace/workspace.dart';

part 'workspace_state.freezed.dart';

/// 작업 폴더 화면.
@freezed
sealed class WorkspaceState with _$WorkspaceState {
  /// 첫 목록을 아직 읽지 못했다.
  const factory WorkspaceState.loading() = WorkspaceLoading;

  /// 두 구역(각 최신순)과 전체 개수 · 바이트.
  const factory WorkspaceState.ready({
    required List<WorkspaceFile> out,
    required List<WorkspaceFile> inbox,
    required int totalCount,
    required int totalBytes,
  }) = WorkspaceReady;

  /// 목록을 읽지 못했다.
  const factory WorkspaceState.failure() = WorkspaceFailure;
}
