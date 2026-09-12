import 'dart:typed_data';

/// 방에 보낼, 압축이 끝난 사진 하나.
///
/// `PostImageDraft` 와 모양이 같지만 합치지 않는다 — 게시물 첨부는 치수를
/// 함께 저장해 목록이 자리를 미리 잡지만(post_images.width/height), 채팅은
/// 치수 컬럼이 없다. feature 간 data 를 공유하지 않는다는 규칙 ⑥ 과도 맞는다.
class ChatImageDraft {
  const ChatImageDraft({
    required this.bytes,
    required this.contentType,
    required this.extension,
  });

  final Uint8List bytes;

  /// Storage 버킷의 allowed_mime_types 와 맞아야 한다.
  final String contentType;

  /// 객체 경로에 붙일 확장자 (`webp` · `jpg`). 플랫폼마다 다르다.
  final String extension;
}
