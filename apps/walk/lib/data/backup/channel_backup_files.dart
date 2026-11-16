import 'dart:io';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../domain/backup/backup_failure.dart';
import '../../domain/backup/backup_files.dart';

/// MainActivity 의 `BackupFileChannel.kt` 로 백업 파일을 저장 · 열기 · 앱 재시작한다.
/// 큰 파일을 메모리에 올리지 않게 네이티브가 스트림으로 복사한다.
@LazySingleton(as: BackupFiles)
class ChannelBackupFiles implements BackupFiles {
  static const channelName = 'com.karma.walk/backup_file';
  static const _channel = MethodChannel(channelName);

  @override
  Future<bool> saveAs(File source, String suggestedName) async {
    final saved = await _invoke<bool>('saveAs', {
      'path': source.path,
      'name': suggestedName,
      'mime': suggestedName.endsWith('.zip')
          ? 'application/zip'
          : 'application/octet-stream',
    });
    return saved ?? false;
  }

  @override
  Future<File?> open() async {
    final path = await _invoke<String>('open');
    return path == null || path.isEmpty ? null : File(path);
  }

  @override
  Future<void> restartApp() => _invoke<void>('restart');

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      throw BackupException(
        e.code == 'no_space' ? BackupFailure.noSpace : BackupFailure.io,
      );
    } on MissingPluginException {
      throw const BackupException(BackupFailure.io);
    }
  }
}
