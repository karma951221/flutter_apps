import '../../../../../core/error/failure.dart';
import '../../../../../core/result/result.dart';
import '../../entity/feed_post.dart';
import '../../repository/feed_repository.dart';

class GetFeedPostsScenario {
  const GetFeedPostsScenario(this._repository);

  static const maxPageSize = 50;

  final FeedRepository _repository;

  Future<Result<List<FeedPost>>> call({
    required int limit,
    required int offset,
  }) {
    if (limit < 1 || limit > maxPageSize || offset < 0) {
      return Future.value(
        const Err(Failure.validation(message: '올바른 피드 조회 범위가 아닙니다')),
      );
    }
    return _repository.getFeedPosts(limit: limit, offset: offset);
  }
}
