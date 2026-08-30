import '../../../../../core/error/failure.dart';
import '../../../../../core/error/failure_code.dart';
import '../../../../../core/result/result.dart';
import '../../entity/post.dart';
import '../../entity/post_update.dart';
import '../../post_policy.dart';
import '../../repository/post_repository.dart';

class UpdatePostScenario {
  const UpdatePostScenario(this._repository);

  final PostRepository _repository;

  Future<Result<Post>> call(String postId, PostUpdate update) {
    if (postId.trim().isEmpty) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '게시물 식별자가 필요합니다',
            failureCode: FailureCode.postIdRequired,
          ),
        ),
      );
    }

    final content = update.content.trim();
    if (content.isEmpty) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '게시물 내용을 입력하세요',
            field: 'content',
            failureCode: FailureCode.postContentRequired,
          ),
        ),
      );
    }
    if (content.length > PostPolicy.maxContentLength) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '게시물은 ${PostPolicy.maxContentLength}자 이하여야 합니다',
            field: 'content',
            failureCode: FailureCode.postTooLong,
          ),
        ),
      );
    }

    return _repository.updatePost(postId, PostUpdate(content: content));
  }
}
