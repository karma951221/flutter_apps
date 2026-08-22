import '../../domain/entity/feed_post.dart';
import '../dto/feed_post_dto.dart';

/// data/domain 경계의 피드 게시물 변환.
extension FeedPostDtoMapper on FeedPostDto {
  FeedPost toEntity() => FeedPost(
    id: id,
    authorId: authorId,
    content: content,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
