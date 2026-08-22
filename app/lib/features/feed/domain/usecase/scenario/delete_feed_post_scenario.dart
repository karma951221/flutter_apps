import '../../../../../core/error/failure.dart';
import '../../../../../core/result/result.dart';
import '../../repository/feed_repository.dart';

class DeleteFeedPostScenario {
  const DeleteFeedPostScenario(this._repository);

  final FeedRepository _repository;

  Future<Result<void>> call(String postId) {
    if (postId.trim().isEmpty) {
      return Future.value(
        const Err(Failure.validation(message: '게시물 식별자가 필요합니다')),
      );
    }
    return _repository.deleteFeedPost(postId);
  }
}
