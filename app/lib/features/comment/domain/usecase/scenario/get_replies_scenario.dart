import '../../../../../core/error/failure.dart';
import '../../../../../core/pagination/cursor_page.dart';
import '../../../../../core/result/result.dart';
import '../../comment_policy.dart';
import '../../entity/post_comment.dart';
import '../../repository/comment_repository.dart';

/// 한 부모의 답글 목록. 부모를 눌렀을 때 읽으므로 첫 조회 페이로드가 답글 수에
/// 좌우되지 않는다. 검증 규칙은 부모 목록과 같다.
class GetRepliesScenario {
  const GetRepliesScenario(this._repository);

  final CommentRepository _repository;

  Future<Result<CursorPage<PostComment>>> call({
    required String parentId,
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
    return _repository.getReplies(
      parentId: parentId,
      limit: limit,
      cursor: cursor,
    );
  }
}
