import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// 모델에 보내는 사진의 긴 변.
const chatImageMaxSide = 1024;

/// [path] 의 사진을 긴 변 [chatImageMaxSide] 안의 JPEG 로 줄인다(EXIF 는 빠진다).
/// 일기 사진 도구와 첨부가 같은 설정을 쓴다. 읽지 못하면 null. 플러그인이라 단위 테스트는 하지 않는다.
Future<Uint8List?> compressChatImage(String path) =>
    FlutterImageCompress.compressWithFile(
      path,
      minWidth: chatImageMaxSide,
      minHeight: chatImageMaxSide,
      quality: 80,
      format: CompressFormat.jpeg,
    );
