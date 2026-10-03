import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

abstract interface class PhotoStorage {
  /// 저장하고 앱 문서 폴더 기준 상대 경로를 돌려준다.
  Future<Result<String>> store({
    required Uint8List bytes,
    required String extension,
  });

  File resolve(String relativePath);

  /// best-effort. 던지지 않는다.
  Future<void> remove(String relativePath);
}
