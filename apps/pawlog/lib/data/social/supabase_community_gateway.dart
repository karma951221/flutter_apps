import 'package:supabase_flutter/supabase_flutter.dart';

import 'walk_post_cursor.dart';

/// 모두의 산책의 Supabase 경계. [SupabaseCommunityRepository] 는 이 계약만 알아 가짜로
/// 바꿔 시험할 수 있다. Supabase 예외는 그대로 던진다 — 변환은 저장소의 몫이다.
///
/// 백엔드는 `supabase/migrations/20261017090722_walk_posts.sql`(schema.md §18).
abstract interface class SupabaseCommunityGateway {
  String? get currentUserId;

  /// `walk_posts_with_author` 를 `(created_at desc, id desc)` 로 [limit] 개.
  /// [before] 가 있으면 그 글보다 뒤(오래된 쪽)만.
  Future<List<Map<String, dynamic>>> fetchPosts({
    required int limit,
    WalkPostCursor? before,
  });

  /// [authorId] 가 [localWalkId] 를 공유 중인지. 보기는 공유 취소된 글을 가린다.
  Future<bool> hasLivePost({
    required String authorId,
    required String localWalkId,
  });

  /// `publish_walk_post` RPC. 글 id.
  Future<String> publish(Map<String, dynamic> params);

  /// `unpublish_walk_post` RPC. 바뀐 행이 있으면 true.
  Future<bool> unpublish(String localWalkId);

  /// 내 좋아요 — `post_id` 만 넣는다(열 GRANT). 겹치면 23505(409)를 던진다.
  Future<void> insertLike(String postId);

  Future<void> deleteLike({required String postId, required String userId});
}

/// 읽기는 요청마다 `retry(enabled: false)` — 사용자가 화면 앞에서 기다리는 읽기라 다시 시도하지
/// 않는다. postgrest 는 실패한 GET 을 기본 3번(1·2·4초 대기) 다시 보내고, `SupabaseClient.from`
/// 은 `PostgrestClientOptions` 의 재시도 설정을 넘기지 않아(supabase 2.16.1) 클라이언트
/// 설정으로는 끌 수 없다. 서버가 멈추면 10초 × 4 + 7초 ≈ 47초를 기다렸다.
class SupabaseClientCommunityGateway implements SupabaseCommunityGateway {
  SupabaseClientCommunityGateway(this._client);

  final SupabaseClient _client;

  static const _view = 'walk_posts_with_author';
  static const _likes = 'walk_post_likes';

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> fetchPosts({
    required int limit,
    WalkPostCursor? before,
  }) async {
    var request = _client.from(_view).select();
    if (before != null) {
      final createdAt = before.createdAt.toIso8601String();
      request = request.or(
        'created_at.lt.$createdAt,'
        'and(created_at.eq.$createdAt,id.lt.${before.id})',
      );
    }
    return request
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit)
        .retry(enabled: false);
  }

  @override
  Future<bool> hasLivePost({
    required String authorId,
    required String localWalkId,
  }) async {
    final rows = await _client
        .from(_view)
        .select('id')
        .eq('author_id', authorId)
        .eq('local_walk_id', localWalkId)
        .limit(1)
        .retry(enabled: false);
    return rows.isNotEmpty;
  }

  @override
  Future<String> publish(Map<String, dynamic> params) async =>
      await _client.rpc<dynamic>('publish_walk_post', params: params) as String;

  @override
  Future<bool> unpublish(String localWalkId) async =>
      await _client.rpc<dynamic>(
            'unpublish_walk_post',
            params: {'p_local_walk_id': localWalkId},
          )
          as bool;

  @override
  Future<void> insertLike(String postId) async {
    await _client.from(_likes).insert({'post_id': postId});
  }

  @override
  Future<void> deleteLike({
    required String postId,
    required String userId,
  }) async {
    await _client
        .from(_likes)
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId);
  }
}
