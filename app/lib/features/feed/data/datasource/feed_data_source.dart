import '../cursor/feed_cursor.dart';
import '../dto/feed_post_dto.dart';

/// 피드 원격 데이터 원천의 계약.
abstract interface class FeedDataSource {
  /// 최신순으로 [limit] 개까지 조회한다. [cursor] 가 null 이면 첫 페이지다.
  Future<List<FeedPostDto>> getPosts({
    required int limit,
    FeedCursor? cursor,
  });
}
