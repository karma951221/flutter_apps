import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entity/feed_source.dart';
import '../cursor/feed_cursor.dart';
import '../dto/feed_post_dto.dart';
import 'feed_data_source.dart';

@LazySingleton(as: FeedDataSource)
class SupabaseFeedDataSource implements FeedDataSource {
  SupabaseFeedDataSource(this._client);

  final SupabaseClient _client;

  /// 작성자를 조인해 내려주는 뷰. posts 를 직접 읽지 않는 이유는
  /// docs/schema.md 의 `posts_with_author` 항목에 있다.
  static const _allSource = 'posts_with_author';

  /// 팔로잉 피드. 위 뷰를 내 follows 로 좁힌 것이라 컬럼·정렬·커서가 같다.
  static const _followingSource = 'following_posts_with_author';

  static const _columns =
      'id, author_id, content, created_at, updated_at, '
      'author_nickname, author_avatar_url, images, '
      'reaction_counts, my_reaction, comment_count, trade_result';

  @override
  Future<List<FeedPostDto>> getPosts({
    required int limit,
    FeedCursor? cursor,
    String? authorId,
    FeedSource source = FeedSource.all,
  }) async {
    // deleted_at 필터를 여기에 쓰지 않는다. 조회 RLS(posts_select_visible)가
    // 삭제행을 가리므로 앱이 빠뜨릴 수 없다. 뷰는 security_invoker = on 이라
    // 그 정책을 그대로 물려받는다. docs/schema.md §2·§6 참고.
    final view = switch (source) {
      FeedSource.all => _allSource,
      FeedSource.following => _followingSource,
    };
    var query = _client.from(view).select(_columns);

    if (authorId != null) query = query.eq('author_id', authorId);

    if (cursor != null) {
      final createdAt = cursor.createdAt.toUtc().toIso8601String();
      // (created_at, id) 사전식 비교. 같은 시각에 두 글이 들어와도 순서가
      // 정해지고 경계에서 중복·누락이 생기지 않는다.
      query = query.or(
        'created_at.lt.$createdAt,'
        'and(created_at.eq.$createdAt,id.lt.${cursor.id})',
      );
    }

    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);

    return rows.map(FeedPostDto.fromJson).toList();
  }
}
