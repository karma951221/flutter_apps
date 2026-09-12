import 'dart:typed_data';

/// 프로필에 올릴, 압축이 끝난 아바타 이미지.
///
/// 바이트와 인코딩 결과([contentType] · [extension])만 보관하므로 domain 은
/// Flutter/Storage SDK 에 의존하지 않는다 (규칙 ⑤). 형식은 플랫폼마다 다르다
/// (Android WebP · 그 밖 JPEG). 게시물 첨부는 치수까지 필요해 별도 타입
/// (`PostImageDraft`)을 쓴다 — feature 끼리 entity 를 빌려오지 않는다 (규칙 ⑥).
class AvatarImageDraft {
  const AvatarImageDraft({
    required this.bytes,
    required this.contentType,
    required this.extension,
  });

  final Uint8List bytes;
  final String contentType;
  final String extension;
}
