import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../cursor/feed_cursor.dart';
import '../dto/feed_post_dto.dart';
import 'feed_data_source.dart';

@LazySingleton(as: FeedDataSource)
class SupabaseFeedDataSource implements FeedDataSource {
  SupabaseFeedDataSource(this._client);

  final SupabaseClient _client;

  static const _columns = 'id, author_id, content, created_at, updated_at';

  @override
  Future<List<FeedPostDto>> getPosts({
    required int limit,
    FeedCursor? cursor,
  }) async {
    // deleted_at 필터를 여기에 쓰지 않는다. 조회 RLS(posts_select_visible)가
    // 삭제행을 가리므로 앱이 빠뜨릴 수 없다. docs/schema.md §2 참고.
    var query = _client.from('posts').select(_columns);

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
