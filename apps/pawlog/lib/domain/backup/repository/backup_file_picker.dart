import 'dart:typed_data';

import 'package:core/core.dart';

/// 가져올 백업 파일 하나를 고르는 경계. 구현은 플랫폼 플러그인에 의존한다.
abstract interface class BackupFilePicker {
  /// 고른 파일의 바이트. 사용자가 취소하면 `Ok(null)`.
  Future<Result<Uint8List?>> pick();
}
