import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'backup_import_result.freezed.dart';

/// 백업 가져오기 결과. 상태가 아니라 한 번 쓰고 버리는 값이다.
@freezed
sealed class BackupImportResult with _$BackupImportResult {
  /// 새로 들어간 반려견 · 산책 수(하나 이상).
  const factory BackupImportResult.imported(int dogs, int walks) =
      BackupImported;

  /// 백업의 항목이 모두 이미 있다.
  const factory BackupImportResult.nothingNew() = BackupNothingNew;

  /// 사용자가 파일 고르기를 취소했다.
  const factory BackupImportResult.cancelled() = BackupImportCancelled;

  /// 읽을 수 없는 백업이다. 아무것도 쓰지 않았다.
  const factory BackupImportResult.invalid() = BackupInvalid;

  const factory BackupImportResult.failed(Failure failure) = BackupImportFailed;
}
