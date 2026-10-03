import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repository/photo_storage.dart';

@LazySingleton(as: PhotoStorage)
class FilePhotoStorage implements PhotoStorage {
  FilePhotoStorage(@Named('walkPhotosRoot') this._root, this._ids);

  final Directory _root;
  final IdGenerator _ids;

  /// iOS 는 컨테이너 절대 경로가 바뀌므로 루트 기준 상대 경로만 돌려준다.
  @override
  Future<Result<String>> store({
    required Uint8List bytes,
    required String extension,
  }) async {
    final relative = '${_ids.newId()}.$extension';
    try {
      await _root.create(recursive: true);
      await File('${_root.path}/$relative').writeAsBytes(bytes, flush: true);
      return Ok(relative);
    } on FileSystemException catch (error) {
      return Err(
        Failure.unknown(
          failureCode: FailureCode.walkPhotoSaveFailed,
          message: error.toString(),
        ),
      );
    }
  }

  @override
  File resolve(String relativePath) => File('${_root.path}/$relativePath');

  @override
  Future<void> remove(String relativePath) async {
    try {
      final file = resolve(relativePath);
      if (file.existsSync()) await file.delete();
    } catch (_) {
      // best-effort.
    }
  }
}
