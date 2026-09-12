import '../cursor/comment_cursor.dart';
import '../dto/post_comment_dto.dart';

/// 작성 결과. 본문과 작성자는 호출부가 이미 알고 있으므로 서버가 정하는 값만
/// 돌려받는다. 왕복을 한 번으로 끝내기 위한 모양이다.
typedef CreatedComment = ({String id, DateTime createdAt});

abstract interface class CommentDataSource {
  /// 부모 댓글을 오래된 순으로 [limit] 개까지. [cursor] 가 null 이면 첫 페이지다.
  Future<List<PostCommentDto>> getComments({
    required String postId,
    required int limit,
    CommentCursor? cursor,
  });

  /// 한 부모의 답글을 오래된 순으로 [limit] 개까지.
  Future<List<PostCommentDto>> getReplies({
    required String parentId,
    required int limit,
    CommentCursor? cursor,
  });

  /// 로그인하지 않았으면 null.
  Future<CreatedComment?> addComment({
    required String postId,
    String? parentId,
    required String content,
  });

  /// 로그인하지 않았으면 null, 남의 댓글이면 false.
  Future<bool?> deleteComment(String commentId);
}
