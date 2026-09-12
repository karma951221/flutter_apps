import 'dart:typed_data';

/// 새 게시물에 첨부할, 압축 완료된 이미지.
///
/// 바이트와 치수, 그리고 인코딩 결과([contentType] · [extension])만 보관하므로
/// domain은 Flutter/Storage SDK에 의존하지 않는다. 형식은 플랫폼마다 다르다
/// (Android WebP · 그 밖 JPEG). 업로드 경로와 Content-Type 은 이 값을 따른다.
class PostImageDraft {
  const PostImageDraft({
    required this.bytes,
    required this.width,
    required this.height,
    required this.contentType,
    required this.extension,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final String contentType;
  final String extension;
}
