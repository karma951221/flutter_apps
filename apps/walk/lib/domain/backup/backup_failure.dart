import 'package:core/core.dart';

/// 백업 · 복원이 실패한 이유. `Failure.validation(field: BackupFailure.x.name)` 로 실어 보낸다.
enum BackupFailure {
  notBackup,
  newerFormat,
  newerAreaSchema,
  wrongPasswordOrCorrupt,
  integrity,
  noSpace,
  cancelled,
  io;

  Failure toFailure() => Failure.validation(field: name);
}

/// 백업 · 복원 도중 [BackupFailure] 로 중단할 때 던진다.
class BackupException implements Exception {
  const BackupException(this.failure);

  final BackupFailure failure;

  @override
  String toString() => 'BackupException($failure)';
}
