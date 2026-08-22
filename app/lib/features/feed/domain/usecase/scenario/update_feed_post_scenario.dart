import '../../../../../core/error/failure.dart';
import '../../../../../core/result/result.dart';
import '../../entity/feed_post.dart';
import '../../entity/feed_post_update.dart';
import '../../repository/feed_repository.dart';

class UpdateFeedPostScenario {
  const UpdateFeedPostScenario(this._repository);

  final FeedRepository _repository;

  Future<Result<FeedPost>> call(String postId, FeedPostUpdate update) {
    final content = update.content.trim();
    if (postId.trim().isEmpty) {
      return Future.value(
        const Err(Failure.validation(message: '게시물 식별자가 필요합니다')),
      );
    }
    if (content.isEmpty) {
      return Future.value(
        const Err(
          Failure.validation(message: '게시물 내용을 입력하세요', field: 'content'),
        ),
      );
    }
    if (content.length > 500) {
      return Future.value(
        const Err(
          Failure.validation(message: '게시물은 500자 이하여야 합니다', field: 'content'),
        ),
      );
    }
    return _repository.updateFeedPost(postId, FeedPostUpdate(content: content));
  }
}
