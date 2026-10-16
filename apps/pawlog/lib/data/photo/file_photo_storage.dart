import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../../domain/photo/repository/photo_storage.dart';

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
  Future<Result<void>> write(String relativePath, Uint8List bytes) async {
    if (!isSafePhotoPath(relativePath)) {
      return Err(
        Failure.validation(
          failureCode: FailureCode.invalidData,
          message: 'unsafe photo path: $relativePath',
        ),
      );
    }
    try {
      final file = resolve(relativePath);
      if (file.existsSync()) return const Ok(null);
      await file.parent.create(recursive: true);
      // 쓰다가 죽어도 최종 경로에 반쪽 파일이 남지 않게 임시 파일에 쓰고 옮긴다.
      final temp = File('${file.path}.tmp');
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(file.path);
      return const Ok(null);
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
