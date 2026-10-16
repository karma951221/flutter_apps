import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

abstract interface class PhotoStorage {
  /// 저장하고 앱 문서 폴더 기준 상대 경로를 돌려준다.
  Future<Result<String>> store({
    required Uint8List bytes,
    required String extension,
  });

  /// 가져온 사진을 같은 상대 경로로 쓴다. 이미 있으면 덮어쓰지 않고 `Ok`.
  /// [isSafePhotoPath] 가 아니면 쓰지 않고 `Err`.
  Future<Result<void>> write(String relativePath, Uint8List bytes);

  File resolve(String relativePath);

  /// best-effort. 던지지 않는다.
  Future<void> remove(String relativePath);
}

/// 루트 밖으로 나가지 않는 상대 경로인가. 비었거나 `/` · `\\` 로 시작하거나
/// `..` 조각이 있으면 아니다(백업 zip 의 경로 탈출 방지).
bool isSafePhotoPath(String relativePath) {
  if (relativePath.isEmpty) return false;
  if (relativePath.startsWith('/') || relativePath.startsWith(r'\')) {
    return false;
  }
  return !relativePath.split(RegExp(r'[/\\]')).contains('..');
}
