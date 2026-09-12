import '../../../post/domain/entity/post_author.dart';
import 'package:feature_reaction/feature_reaction.dart';
import '../../domain/entity/post_comment.dart';
import '../cursor/comment_cursor.dart';
import '../dto/post_comment_dto.dart';

/// data/domain 경계의 댓글 변환.
extension PostCommentDtoMapper on PostCommentDto {
  PostAuthor toAuthor() => PostAuthor(
    id: authorId,
    nickname: authorNickname,
    avatarUrl: authorAvatarUrl,
  );

  PostComment toEntity() => PostComment(
    id: id,
    postId: postId,
    parentId: parentId,
    author: toAuthor(),
    content: content,
    createdAt: createdAt,
    deletedAt: deletedAt,
    replyCount: replyCount,
    reactions: ReactionSummary.fromRaw(reactionCounts, myReaction),
  );

  /// 이 행을 마지막 항목으로 하는 다음 페이지 커서.
  CommentCursor toCursor() => CommentCursor(createdAt: createdAt, id: id);
}
