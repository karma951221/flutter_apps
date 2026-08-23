import '../../../../../core/error/failure.dart';
import '../../../../../core/pagination/cursor_page.dart';
import '../../../../../core/result/result.dart';
import '../../comment_policy.dart';
import '../../entity/post_comment.dart';
import '../../repository/comment_repository.dart';

/// 부모 댓글 목록. 오래된 순 커서 페이지네이션이다.
class GetCommentsScenario {
  const GetCommentsScenario(this._repository);

  final CommentRepository _repository;

  Future<Result<CursorPage<PostComment>>> call({
    required String postId,
    required int limit,
    String? cursor,
  }) {
    if (limit < 1 || limit > CommentPolicy.maxPageSize) {
      return Future.value(
        const Err(Failure.validation(message: '올바른 댓글 조회 범위가 아닙니다')),
      );
    }
    if (cursor != null && cursor.trim().isEmpty) {
      return Future.value(
        const Err(
          Failure.validation(message: '잘못된 댓글 커서입니다', field: 'cursor'),
        ),
      );
    }
    return _repository.getComments(
      postId: postId,
      limit: limit,
      cursor: cursor,
    );
  }
}
