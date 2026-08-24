import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_image.freezed.dart';

/// 게시물에 연결된 공개 이미지.
@freezed
class PostImage with _$PostImage {
  const PostImage({
    required this.id,
    required this.url,
    required this.width,
    required this.height,
    required this.sortOrder,
  });

  @override
  final String id;
  @override
  final String url;
  @override
  final int width;
  @override
  final int height;
  @override
  final int sortOrder;
}
