import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:l10n/l10n.dart';

import '../../domain/backup/entity/backup_import_result.dart';

/// 가져오기 결과의 스낵바 문구. 취소는 알릴 것이 없어 null 이다.
String? backupImportMessage(BackupImportResult result, AppLocalizations l10n) =>
    switch (result) {
      BackupImported(:final dogs, :final walks) => l10n.walkBackupImported(
        dogs,
        walks,
      ),
      BackupNothingNew() => l10n.walkBackupNothingNew,
      BackupInvalid() => l10n.walkBackupInvalid,
      BackupImportFailed() => l10n.walkBackupImportFailed,
      BackupImportCancelled() => null,
    };

/// 피드와 첫 실행 등록 화면이 같은 결과를 같은 스낵바로 알린다.
void showBackupImportResult(BuildContext context, BackupImportResult result) {
  final message = backupImportMessage(result, AppLocalizations.of(context));
  if (message == null) return;
  AppSnackBar.show(
    context,
    message: message,
    type: switch (result) {
      BackupInvalid() || BackupImportFailed() => AppSnackBarType.error,
      _ => AppSnackBarType.info,
    },
  );
}
