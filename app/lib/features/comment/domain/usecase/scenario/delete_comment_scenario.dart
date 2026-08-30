import '../../../../../core/error/failure.dart';
import '../../../../../core/error/failure_code.dart';
import '../../../../../core/result/result.dart';
import '../../repository/comment_repository.dart';

/// 내 댓글 삭제. 권한 경계는 앱이 아니라 soft_delete_post_comment() 안의
/// `author_id = auth.uid()` 다 — 남의 댓글을 지우려 하면 false 가 온다.
class DeleteCommentScenario {
  const DeleteCommentScenario(this._repository);

  final CommentRepository _repository;

  Future<Result<bool>> call(String commentId) {
    if (commentId.trim().isEmpty) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '삭제할 댓글을 찾을 수 없습니다',
            failureCode: FailureCode.commentDeleteTargetMissing,
          ),
        ),
      );
    }
    return _repository.deleteComment(commentId);
  }
}
