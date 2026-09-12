import '../../../../core/pagination/cursor_page.dart';
import '../../../../core/result/result.dart';
import '../../../post/domain/entity/post_author.dart';
import '../entity/post_comment.dart';

/// 댓글 저장소.
///
/// 부모 댓글과 답글을 **별도로** 읽는다. 답글은 부모를 눌렀을 때 가져오므로
/// 첫 조회 페이로드가 답글 수에 좌우되지 않는다. 두 조회는 같은 뷰를 읽고
/// 좁히는 조건만 다르다.
abstract interface class CommentRepository {
  Future<Result<CursorPage<PostComment>>> getComments({
    required String postId,
    required int limit,
    String? cursor,
  });

  Future<Result<CursorPage<PostComment>>> getReplies({
    required String parentId,
    required int limit,
    String? cursor,
  });

  /// [author] 는 세션의 본인이다. 방금 쓴 댓글을 다시 조회하지 않기 위해
  /// 호출부가 넘긴다 (피드의 `prependPost` 와 같은 방식).
  Future<Result<PostComment>> addComment({
    required String postId,
    String? parentId,
    required String content,
    required PostAuthor author,
  });

  /// 지워졌으면 true, 없거나 남의 댓글이면 false.
  Future<Result<bool>> deleteComment(String commentId);
}
