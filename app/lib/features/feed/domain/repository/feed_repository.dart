import '../../../../core/result/result.dart';
import '../entity/feed_post.dart';
import '../entity/feed_post_draft.dart';
import '../entity/feed_post_update.dart';

/// 피드 게시물 저장소.
///
/// 로그인한 사용자의 식별은 구현체가 처리하므로 호출부가 인증 SDK를 알 필요가 없다.
abstract interface class FeedRepository {
  /// 최신순 피드 목록을 조회한다.
  Future<Result<List<FeedPost>>> getFeedPosts({
    required int limit,
    required int offset,
  });

  /// 게시물 하나를 조회한다.
  Future<Result<FeedPost>> getFeedPost(String postId);

  /// 로그인한 사용자의 새 게시물을 작성한다.
  Future<Result<FeedPost>> createFeedPost(FeedPostDraft draft);

  /// 로그인한 사용자가 작성한 게시물을 수정한다.
  Future<Result<FeedPost>> updateFeedPost(String postId, FeedPostUpdate update);

  /// 로그인한 사용자가 작성한 게시물을 삭제한다.
  Future<Result<void>> deleteFeedPost(String postId);
}
