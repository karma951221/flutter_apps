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

/// 루트 밖으로 나가지 않는 상대 경로인가(백업 zip 의 경로 탈출 방지).
///
/// 비었거나, `\0` 이 있거나, `/` · `\` 로 시작하거나, `/` · `\` 로 나눈 조각 중
/// 빈 것 · `.` · `..` · 드라이브 접두사(`C:`)가 있으면 아니다.
bool isSafePhotoPath(String relativePath) {
  if (relativePath.isEmpty || relativePath.contains('\u0000')) return false;
  final drive = RegExp(r'^[A-Za-z]:');
  for (final segment in relativePath.split(RegExp(r'[/\\]'))) {
    if (segment.isEmpty || segment == '.' || segment == '..') return false;
    if (drive.hasMatch(segment)) return false;
  }
  return true;
}
