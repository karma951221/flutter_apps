import '../../../../../core/error/failure.dart';
import '../../../../../core/result/result.dart';
import '../../entity/feed_post.dart';
import '../../entity/feed_post_draft.dart';
import '../../repository/feed_repository.dart';

/// 게시물 작성 전 domain 입력을 검증하고 저장을 요청한다.
class CreateFeedPostScenario {
  const CreateFeedPostScenario(this._repository);

  static const maxContentLength = 500;

  final FeedRepository _repository;

  Future<Result<FeedPost>> call(FeedPostDraft draft) {
    final content = draft.content.trim();
    if (content.isEmpty) {
      return Future.value(
        const Err(
          Failure.validation(message: '게시물 내용을 입력하세요', field: 'content'),
        ),
      );
    }
    if (content.length > maxContentLength) {
      return Future.value(
        const Err(
          Failure.validation(message: '게시물은 500자 이하여야 합니다', field: 'content'),
        ),
      );
    }

    return _repository.createFeedPost(FeedPostDraft(content: content));
  }
}
