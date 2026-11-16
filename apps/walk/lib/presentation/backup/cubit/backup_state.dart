import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/backup/backup_failure.dart';
import '../../../domain/backup/backup_service.dart';
import '../../../domain/backup/restore_notice.dart';

part 'backup_state.freezed.dart';

/// 진행 표시가 보여 줄 단계.
enum BackupStep { exporting, saving, inspecting, restoring, undoing }

/// 백업 화면. [BackupIdle] 말고는 지나가는 상태다 — 화면이 알림 · 대화상자를 띄우고
/// cubit 이 다음 상태로 넘긴다.
@freezed
sealed class BackupState with _$BackupState {
  /// 행을 그리는 상태. [daysAgo] 는 [lastAt] 부터 오늘까지 지난 날 수, [stale] 은 30일 넘음.
  const factory BackupState.idle({
    DateTime? lastAt,
    int? daysAgo,
    @Default(false) bool stale,
    @Default(false) bool hasUndo,
  }) = BackupIdle;

  /// 전체 화면 진행 표시로 다른 조작을 막는다. [progress] 는 0..1(퍼센트로 보인다),
  /// null 이면 비율을 모르는 단계다.
  const factory BackupState.working(BackupStep step, {double? progress}) =
      BackupWorking;

  /// 백업 파일을 저장했다([bytes] = 파일 크기).
  const factory BackupState.exported(int bytes) = BackupExported;

  /// 고른 파일이 암호화돼 있다 — 비밀번호를 묻는다. [wrong] 이면 방금 넣은 것이 틀렸다.
  const factory BackupState.passwordNeeded({@Default(false) bool wrong}) =
      BackupPasswordNeeded;

  /// 검사를 마쳤다 — 복원할 영역을 고른다.
  const factory BackupState.inspected(InspectedBackup backup) = BackupInspected;

  /// 복원(또는 되돌리기)을 마쳤다 — 안내를 보이고 앱을 다시 시작한다.
  const factory BackupState.restored(Set<RestoreNotice> notices) =
      BackupRestored;

  /// 실패했다. [needsRestart] 면 복원을 끝내지 못한 채라 다시 시작해야 한다.
  const factory BackupState.failed(
    BackupFailure failure, {
    @Default(false) bool needsRestart,
  }) = BackupFailed;
}
