import '../../domain/entity/post.dart';
import '../../domain/entity/post_image.dart';
import '../dto/post_dto.dart';

/// data/domain 경계의 게시물 변환.
extension PostDtoMapper on PostDto {
  Post toEntity() => Post(
    id: id,
    authorId: authorId,
    content: content,
    createdAt: createdAt,
    updatedAt: updatedAt,
    images: images
        .map(
          (image) => PostImage(
            id: image.id,
            url: image.url,
            width: image.width,
            height: image.height,
            sortOrder: image.sortOrder,
          ),
        )
        .toList(),
  );
}
