import 'package:l10n/l10n.dart';

import '../../../domain/backup/backup_area_id.dart';
import '../../../domain/backup/backup_failure.dart';
import '../../../domain/backup/restore_notice.dart';
import '../../common/format_bytes.dart';
import '../cubit/backup_state.dart';

/// 백업 화면 · 시트가 함께 쓰는 문구.
extension BackupLabels on AppLocalizations {
  String backupAreaName(BackupAreaId id) => switch (id) {
    BackupAreaId.diary => walkBackupAreaDiary,
    BackupAreaId.chat => walkBackupAreaChat,
    BackupAreaId.wiki => walkBackupAreaWiki,
    BackupAreaId.alarm => walkBackupAreaAlarm,
    BackupAreaId.settings => walkBackupAreaSettings,
    BackupAreaId.location => walkBackupAreaLocation,
  };

  /// 영역 개수 한 줄(영역 `counts()` · manifest `counts` 의 키). 개수가 없는 영역(앱 설정)은 null.
  /// [bytes] 가 1MB 를 넘으면 뒤에 크기를 붙인다.
  String? backupAreaCounts(
    BackupAreaId id,
    Map<String, int> counts, {
    int? bytes,
  }) {
    int n(String key) => counts[key] ?? 0;
    final text = switch (id) {
      BackupAreaId.diary when counts.isNotEmpty => walkBackupCountDiary(
        n('entries'),
        n('media'),
      ),
      BackupAreaId.chat when counts.isNotEmpty => walkBackupCountChat(
        n('conversations'),
        n('files'),
      ),
      BackupAreaId.wiki when counts.isNotEmpty => walkBackupCountItems(
        n('notes'),
      ),
      BackupAreaId.alarm when counts.isNotEmpty => walkBackupCountItems(
        n('alarms'),
      ),
      BackupAreaId.location when counts.isNotEmpty => walkBackupCountPoints(
        n('points'),
      ),
      _ => null,
    };
    if (text == null || bytes == null || bytes < 1024 * 1024) return text;
    return walkBackupSizeSuffix(text, formatBytes(bytes));
  }

  String backupFailure(BackupFailure failure) => switch (failure) {
    BackupFailure.notBackup => walkBackupFailNotBackup,
    BackupFailure.newerFormat ||
    BackupFailure.newerAreaSchema => walkBackupFailNewer,
    BackupFailure.wrongPasswordOrCorrupt => walkBackupFailPassword,
    BackupFailure.integrity => walkBackupFailIntegrity,
    BackupFailure.noSpace => walkBackupFailNoSpace,
    BackupFailure.cancelled => walkBackupFailCancelled,
    BackupFailure.io => walkBackupFailIo,
  };

  String backupStep(BackupStep step) => switch (step) {
    BackupStep.exporting => walkBackupStepExporting,
    BackupStep.saving => walkBackupStepSaving,
    BackupStep.inspecting => walkBackupStepInspecting,
    BackupStep.restoring => walkBackupStepRestoring,
    BackupStep.undoing => walkBackupStepUndoing,
  };

  /// 복원 결과의 안내 줄. 위치 기록은 보관 기간 안내를 함께 단다.
  String restoreNotice(RestoreNotice notice) => switch (notice) {
    RestoreNotice.alarmSoundFallback => walkBackupNoticeAlarmSound,
    RestoreNotice.alarmResyncFailed => walkBackupNoticeAlarmResync,
    RestoreNotice.alarmPermissionNeeded => walkBackupNoticeAlarmPermission,
    RestoreNotice.locationRecordingOff =>
      '$walkBackupNoticeLocationOff $walkBackupNoticeLocationRetention',
    RestoreNotice.apiKeyNeeded => walkBackupNoticeApiKey,
  };
}
