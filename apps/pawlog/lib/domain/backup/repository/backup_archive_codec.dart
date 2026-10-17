import 'dart:typed_data';

import 'package:core/core.dart';

/// 백업 json 과 사진을 파일 하나(zip)로 묶고 푸는 경계.
///
/// 사진 맵의 키는 사진 루트 기준 상대 경로다(`photos/` 접두사 없이).
abstract interface class BackupArchiveCodec {
  Future<Uint8List> pack({
    required String json,
    required Map<String, Uint8List> photos,
  });

  /// zip 이 아니거나 `backup.json` 이 없거나 사진 경로가 루트 밖을 가리키면 `Err`.
  Future<Result<({String json, Map<String, Uint8List> photos})>> unpack(
    Uint8List bytes,
  );
}
