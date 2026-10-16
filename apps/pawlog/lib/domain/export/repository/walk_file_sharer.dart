import 'dart:typed_data';

import 'package:core/core.dart';

/// 만든 파일을 OS 공유 시트로 넘기는 경계. 구현은 플랫폼 플러그인에 의존한다.
abstract interface class WalkFileSharer {
  Future<Result<void>> shareFile({
    required String fileName,
    required String contents,
    required String mimeType,
  });

  /// 바이너리 파일(백업 zip 등)을 같은 방식으로 공유한다.
  Future<Result<void>> shareBytes({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });
}
