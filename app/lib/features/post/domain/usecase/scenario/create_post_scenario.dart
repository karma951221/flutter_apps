import '../../../../../core/error/failure.dart';
import '../../../../../core/result/result.dart';
import '../../entity/post.dart';
import '../../entity/post_draft.dart';
import '../../post_policy.dart';
import '../../repository/post_repository.dart';

/// 게시물 작성 전 domain 입력을 검증하고 저장을 요청한다.
class CreatePostScenario {
  const CreatePostScenario(this._repository);

  final PostRepository _repository;

  Future<Result<Post>> call(PostDraft draft) {
    final content = draft.content.trim();
    if (content.isEmpty) {
      return Future.value(
        const Err(
          Failure.validation(message: '게시물 내용을 입력하세요', field: 'content'),
        ),
      );
    }
    if (content.length > PostPolicy.maxContentLength) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '게시물은 ${PostPolicy.maxContentLength}자 이하여야 합니다',
            field: 'content',
          ),
        ),
      );
    }

    return _repository.createPost(PostDraft(content: content));
  }
}
