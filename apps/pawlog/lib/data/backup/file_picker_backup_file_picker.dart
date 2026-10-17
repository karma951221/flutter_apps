import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

import '../../domain/backup/repository/backup_file_picker.dart';

/// file_picker 13 은 `withData` 를 없앴으므로 고른 뒤 `readAsBytes` 로 읽는다.
///
/// 확장자 · MIME 으로 거르지 않는다(`FileType.any`). 문서 제공자마다 zip 을
/// `application/zip` · `application/x-zip-compressed` · `application/octet-stream` 등으로
/// 달리 적어 걸러지면 고를 수 없게 된다. zip 이 아니면 `unpack` 이 읽지 못함으로 돌려준다.
@LazySingleton(as: BackupFilePicker)
class FilePickerBackupFilePicker implements BackupFilePicker {
  @override
  Future<Result<Uint8List?>> pick() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.any);
      if (file == null) return const Ok(null);
      try {
        return Ok(await file.readAsBytes());
      } finally {
        await _clearTemporaryCopy();
      }
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }

  /// 안드로이드는 고른 파일을 앱 캐시에 복사해 준다. 백업 전체가 남지 않게 읽은 뒤
  /// 지운다. best-effort — 실패해도 던지지 않는다.
  Future<void> _clearTemporaryCopy() async {
    try {
      await FilePicker.clearTemporaryFiles();
    } catch (_) {
      // best-effort.
    }
  }
}
