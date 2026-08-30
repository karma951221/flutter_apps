import 'package:injectable/injectable.dart';

import '../../../../core/pagination/cursor_page.dart';
import '../../../../core/result/result.dart';
import '../entity/feed_post.dart';
import '../entity/feed_source.dart';
import '../repository/feed_repository.dart';
import 'scenario/get_feed_posts_scenario.dart';

/// 피드 feature 의 presentation 진입점.
abstract interface class FeedUseCase {
  Future<Result<CursorPage<FeedPost>>> getFeedPosts({
    int limit,
    String? cursor,
    String? authorId,
    FeedSource source,
  });
}

@LazySingleton(as: FeedUseCase)
class DefaultFeedUseCase implements FeedUseCase {
  DefaultFeedUseCase(this._repository);

  final FeedRepository _repository;

  @override
  Future<Result<CursorPage<FeedPost>>> getFeedPosts({
    int limit = 20,
    String? cursor,
    String? authorId,
    FeedSource source = FeedSource.all,
  }) => GetFeedPostsScenario(_repository)(
    limit: limit,
    cursor: cursor,
    authorId: authorId,
    source: source,
  );
}
