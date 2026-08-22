import '../../../../../core/error/failure.dart';
import '../../../../../core/result/result.dart';
import '../../entity/feed_post.dart';
import '../../repository/feed_repository.dart';

class GetFeedPostScenario {
  const GetFeedPostScenario(this._repository);

  final FeedRepository _repository;

  Future<Result<FeedPost>> call(String postId) {
    if (postId.trim().isEmpty) {
      return Future.value(
        const Err(Failure.validation(message: '게시물 식별자가 필요합니다')),
      );
    }
    return _repository.getFeedPost(postId);
  }
}
