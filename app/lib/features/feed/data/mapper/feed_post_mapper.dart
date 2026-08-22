import '../../../post/domain/entity/post.dart';
import '../cursor/feed_cursor.dart';
import '../dto/feed_post_dto.dart';

/// data/domain 경계의 피드 게시물 변환.
///
/// 피드는 post feature 의 domain entity 를 그대로 쓴다. 같은 게시물을 두 벌로
/// 표현하지 않기 위해서다. feature 간 참조는 domain 까지만 허용된다.
extension FeedPostDtoMapper on FeedPostDto {
  Post toEntity() => Post(
    id: id,
    authorId: authorId,
    content: content,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  /// 이 행을 마지막 항목으로 하는 다음 페이지 커서.
  FeedCursor toCursor() => FeedCursor(createdAt: createdAt, id: id);
}
