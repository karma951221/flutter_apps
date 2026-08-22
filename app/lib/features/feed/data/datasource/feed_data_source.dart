import '../../domain/entity/feed_post_draft.dart';
import '../../domain/entity/feed_post_update.dart';
import '../dto/feed_post_dto.dart';

/// 피드 원격 데이터 원천의 계약.
abstract interface class FeedDataSource {
  Future<List<FeedPostDto>> getFeedPosts({
    required int limit,
    required int offset,
  });
  Future<FeedPostDto> getFeedPost(String postId);
  Future<FeedPostDto?> createFeedPost(FeedPostDraft draft);
  Future<FeedPostDto?> updateFeedPost(String postId, FeedPostUpdate update);
  Future<FeedPostDto?> deleteFeedPost(String postId);
}
