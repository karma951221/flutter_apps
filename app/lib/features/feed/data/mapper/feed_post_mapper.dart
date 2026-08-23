import '../../../post/domain/entity/post.dart';
import '../../../post/domain/entity/post_author.dart';
import '../../../post/domain/entity/post_image.dart';
import '../../../reaction/domain/entity/reaction_summary.dart';
import '../../domain/entity/feed_post.dart';
import '../cursor/feed_cursor.dart';
import '../dto/feed_post_dto.dart';

/// data/domain 경계의 피드 항목 변환.
///
/// 게시물 자체는 post feature 의 domain entity 를 그대로 쓴다. 같은 게시물을
/// 두 벌로 표현하지 않기 위해서다. feature 간 참조는 domain 까지만 허용된다.
extension FeedPostDtoMapper on FeedPostDto {
  Post toPost() => Post(
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

  PostAuthor toAuthor() => PostAuthor(
    id: authorId,
    nickname: authorNickname,
    avatarUrl: authorAvatarUrl,
  );

  FeedPost toEntity() => FeedPost(
    post: toPost(),
    author: toAuthor(),
    reactions: ReactionSummary.fromRaw(reactionCounts, myReaction),
    commentCount: commentCount,
  );

  /// 이 행을 마지막 항목으로 하는 다음 페이지 커서.
  FeedCursor toCursor() => FeedCursor(createdAt: createdAt, id: id);
}
