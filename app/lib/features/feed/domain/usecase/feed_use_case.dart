import 'package:injectable/injectable.dart';

import '../../../../core/pagination/cursor_page.dart';
import '../../../../core/result/result.dart';
import '../../../post/domain/entity/post.dart';
import '../../../post/domain/usecase/post_use_case.dart';
import '../entity/feed_post.dart';
import '../entity/feed_source.dart';
import '../repository/feed_repository.dart';
import 'scenario/get_feed_posts_scenario.dart';

/// 피드 feature 의 presentation 진입점.
abstract interface class FeedUseCase {
  /// 이 세션에서 방금 만들어진 게시물. post feature 가 알리는 것을 그대로
  /// 흘려보낸다.
  ///
  /// 목록 화면은 자기 feature 의 facade 하나만 주입받으므로(아키텍처 규칙 ③)
  /// `PostUseCase` 를 직접 듣지 못한다. 대신 domain 끼리는 참조할 수 있어
  /// (규칙 ⑥) 여기서 다시 내보낸다.
  Stream<Post> get createdPosts;

  Future<Result<CursorPage<FeedPost>>> getFeedPosts({
    int limit,
    String? cursor,
    String? authorId,
    FeedSource source,
  });
}

@LazySingleton(as: FeedUseCase)
class DefaultFeedUseCase implements FeedUseCase {
  DefaultFeedUseCase(this._repository, this._postUseCase);

  final FeedRepository _repository;
  final PostUseCase _postUseCase;

  @override
  Stream<Post> get createdPosts => _postUseCase.createdPosts;

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
