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

  Map<String, Object?> toMap() => {
    'id': id,
    'url': url,
    'width': width,
    'height': height,
    'sort_order': sortOrder,
  };

  static PostImage? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final url = raw['url'];
    final width = raw['width'];
    final height = raw['height'];
    final sortOrder = raw['sort_order'];
    if (id is! String ||
        url is! String ||
        width is! int ||
        height is! int ||
        sortOrder is! int) {
      return null;
    }
    return PostImage(
      id: id,
      url: url,
      width: width,
      height: height,
      sortOrder: sortOrder,
    );
  }
}
