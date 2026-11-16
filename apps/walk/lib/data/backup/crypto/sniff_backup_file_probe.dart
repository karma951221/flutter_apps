import 'dart:io';

import 'package:injectable/injectable.dart';

import '../../../domain/backup/backup_file_probe.dart';
import 'backup_cipher.dart';

/// [sniffBackupFile] 로 가른다.
@LazySingleton(as: BackupFileProbe)
class SniffBackupFileProbe implements BackupFileProbe {
  @override
  Future<bool> isEncrypted(File file) async =>
      await sniffBackupFile(file) == BackupFileKind.encrypted;
}
