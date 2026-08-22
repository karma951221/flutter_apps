import 'package:injectable/injectable.dart';

import '../../../../core/result/result.dart';
import '../entity/feed_post.dart';
import '../entity/feed_post_draft.dart';
import '../entity/feed_post_update.dart';
import '../repository/feed_repository.dart';
import 'scenario/create_feed_post_scenario.dart';
import 'scenario/delete_feed_post_scenario.dart';
import 'scenario/get_feed_post_scenario.dart';
import 'scenario/get_feed_posts_scenario.dart';
import 'scenario/update_feed_post_scenario.dart';

/// 피드 feature의 presentation 진입점.
abstract interface class FeedUseCase {
  Future<Result<List<FeedPost>>> getFeedPosts({int limit = 20, int offset = 0});

  Future<Result<FeedPost>> getFeedPost(String postId);

  Future<Result<FeedPost>> createFeedPost(FeedPostDraft draft);

  Future<Result<FeedPost>> updateFeedPost(String postId, FeedPostUpdate update);

  Future<Result<void>> deleteFeedPost(String postId);
}

@LazySingleton(as: FeedUseCase)
class DefaultFeedUseCase implements FeedUseCase {
  DefaultFeedUseCase(this._repository);

  final FeedRepository _repository;

  @override
  Future<Result<List<FeedPost>>> getFeedPosts({
    int limit = 20,
    int offset = 0,
  }) => GetFeedPostsScenario(_repository)(limit: limit, offset: offset);

  @override
  Future<Result<FeedPost>> getFeedPost(String postId) =>
      GetFeedPostScenario(_repository)(postId);

  @override
  Future<Result<FeedPost>> createFeedPost(FeedPostDraft draft) =>
      CreateFeedPostScenario(_repository)(draft);

  @override
  Future<Result<FeedPost>> updateFeedPost(
    String postId,
    FeedPostUpdate update,
  ) => UpdateFeedPostScenario(_repository)(postId, update);

  @override
  Future<Result<void>> deleteFeedPost(String postId) =>
      DeleteFeedPostScenario(_repository)(postId);
}
