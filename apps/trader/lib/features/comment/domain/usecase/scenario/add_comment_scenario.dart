import '../../../../../core/error/failure.dart';
import '../../../../../core/error/failure_code.dart';
import '../../../../../core/result/result.dart';
import '../../../../post/domain/entity/post_author.dart';
import '../../comment_policy.dart';
import '../../entity/post_comment.dart';
import '../../repository/comment_repository.dart';

/// 댓글·답글 작성. 앞뒤 공백을 다듬고 길이를 확인한 뒤 저장한다.
///
/// 길이 검증은 UX 이고 최종 판정은 DB 의 CHECK 다. 두 값이 어긋나면 사용자에게
/// 날것의 DB 오류가 가므로 `CommentPolicy` 가 같은 숫자를 들고 있다.
/// 2단 제한도 마찬가지로 최종 판정은 DB 트리거다.
class AddCommentScenario {
  const AddCommentScenario(this._repository);

  final CommentRepository _repository;

  Future<Result<PostComment>> call({
    required String postId,
    String? parentId,
    required String content,
    required PostAuthor author,
  }) {
    final trimmed = content.trim();

    if (trimmed.isEmpty) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '댓글 내용을 입력해 주세요',
            field: 'content',
            failureCode: FailureCode.commentContentRequired,
          ),
        ),
      );
    }
    if (trimmed.length > CommentPolicy.maxContentLength) {
      return Future.value(
        Err(
          Failure.validation(
            message: '댓글은 ${CommentPolicy.maxContentLength}자까지 쓸 수 있습니다',
            field: 'content',
            failureCode: FailureCode.commentTooLong,
          ),
        ),
      );
    }

    return _repository.addComment(
      postId: postId,
      parentId: parentId,
      content: trimmed,
      author: author,
    );
  }
}
