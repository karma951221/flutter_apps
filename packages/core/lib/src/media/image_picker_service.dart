import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

/// 선택한 이미지를 앱에서 업로드할 수 있는 바이트로 만든다.
///
/// 원본 파일 경로나 `XFile`은 presentation 밖으로 내보내지 않는다. 긴 변을
/// 1080px로 제한해 저장소·전송량을 일정하게 유지한다.
///
/// 인코딩 형식은 플랫폼마다 다르다. flutter_image_compress 는 iOS 에서 WebP 를
/// **인코딩하지 못하므로**, Android 는 WebP, 그 밖은 JPEG 으로 만든다. 결과
/// 형식을 [contentType] · [extension] 으로 함께 알려서 업로드 쪽이 경로와
/// Content-Type 을 실제 바이트에 맞추게 한다.
class PreparedImage {
  const PreparedImage({
    required this.bytes,
    required this.width,
    required this.height,
    required this.contentType,
    required this.extension,
  });

  final Uint8List bytes;
  final int width;
  final int height;

  /// Storage 에 올릴 때 쓸 MIME 타입. 버킷의 allowed_mime_types 와 맞아야 한다.
  final String contentType;

  /// 객체 경로에 붙일 확장자 (`webp` · `jpg`).
  final String extension;
}

@lazySingleton
class ImagePickerService {
  ImagePickerService() : _picker = ImagePicker();

  final ImagePicker _picker;

  /// 단일 선택이 필요한 아바타 등에서 사용한다.
  Future<XFile?> pickImage() => _picker.pickImage(
    source: ImageSource.gallery,
    requestFullMetadata: false,
  );

  /// 카메라로 한 장 찍어 [prepare] 한 결과를 돌려준다. 취소하면 null.
  Future<PreparedImage?> captureImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      requestFullMetadata: false,
    );
    return file == null ? null : prepare(file);
  }

  Future<List<PreparedImage>> pickImages({required int limit}) async {
    final files = await _picker.pickMultiImage(
      requestFullMetadata: false,
      imageQuality: 100,
    );
    final selected = files.take(limit);
    return Future.wait(selected.map(prepare));
  }

  /// Compress one selected image using the shared X3 media policy.
  Future<PreparedImage> prepare(XFile file) async {
    final original = await file.readAsBytes();

    // 원본 치수는 축소 목표를 계산하는 데만 쓴다. EXIF 회전이 반영돼 있지 않아
    // 세로 사진의 가로·세로가 뒤집혀 있을 수 있기 때문이다.
    final (originalWidth, originalHeight) = await _decodeSize(original);
    final longest = originalWidth > originalHeight
        ? originalWidth
        : originalHeight;
    final scale = longest > 1080 ? 1080 / longest : 1.0;

    final format = defaultTargetPlatform == TargetPlatform.android
        ? CompressFormat.webp
        : CompressFormat.jpeg;
    final compressed = await FlutterImageCompress.compressWithList(
      original,
      minWidth: (originalWidth * scale).round(),
      minHeight: (originalHeight * scale).round(),
      quality: 80,
      format: format,
    );
    final bytes = Uint8List.fromList(compressed);

    // 치수는 **압축 결과**에서 읽는다. FlutterImageCompress 는 EXIF 회전을
    // 픽셀에 적용해 내보내므로, 원본 치수를 그대로 쓰면 세로 사진이 가로로
    // 기록된다.
    final (width, height) = await _decodeSize(bytes);

    return PreparedImage(
      bytes: bytes,
      width: width,
      height: height,
      contentType: format == CompressFormat.webp ? 'image/webp' : 'image/jpeg',
      extension: format == CompressFormat.webp ? 'webp' : 'jpg',
    );
  }

  Future<(int, int)> _decodeSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      try {
        return (frame.image.width, frame.image.height);
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}
