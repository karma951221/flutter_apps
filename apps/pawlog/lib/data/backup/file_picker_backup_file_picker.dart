import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

import '../../domain/backup/repository/backup_file_picker.dart';

/// file_picker 13 은 `withData` 를 없앴으므로 고른 뒤 `readAsBytes` 로 읽는다.
@LazySingleton(as: BackupFilePicker)
class FilePickerBackupFilePicker implements BackupFilePicker {
  @override
  Future<Result<Uint8List?>> pick() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['zip'],
      );
      if (file == null) return const Ok(null);
      return Ok(await file.readAsBytes());
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }
}
