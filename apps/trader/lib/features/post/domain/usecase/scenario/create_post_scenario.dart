import 'package:core/core.dart';
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

    if (draft.images.length > PostPolicy.maxImageCount) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '사진은 ${PostPolicy.maxImageCount}장까지 첨부할 수 있습니다',
            field: 'images',
            failureCode: FailureCode.postImageLimit,
          ),
        ),
      );
    }

    // 본문만 정규화하고 첨부와 판은 받은 그대로 넘긴다. 여기서 draft 를 새로
    // 만들면서 images 나 tradeSessionId 를 빠뜨리면 datasource 가 텍스트 전용
    // 경로를 타고 사진과 판이 조용히 사라진다.
    return _repository.createPost(
      PostDraft(
        content: content,
        images: draft.images,
        tradeSessionId: draft.tradeSessionId,
      ),
    );
  }
}
