import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../cursor/comment_cursor.dart';
import '../dto/post_comment_dto.dart';
import 'comment_data_source.dart';

@LazySingleton(as: CommentDataSource)
class SupabaseCommentDataSource implements CommentDataSource {
  SupabaseCommentDataSource(this._client);

  final SupabaseClient _client;

  /// 본문에 닿는 유일한 경로. post_comments 테이블에는 content SELECT 권한이
  /// 없다 — docs/schema.md 의 post_comments_visible 항목 참고.
  static const _source = 'post_comments_visible';

  static const _columns =
      'id, post_id, parent_id, author_id, content, created_at, deleted_at, '
      'author_nickname, author_avatar_url, reply_count, '
      'reaction_counts, my_reaction';

  @override
  Future<List<PostCommentDto>> getComments({
    required String postId,
    required int limit,
    CommentCursor? cursor,
  }) async {
    var query = _client
        .from(_source)
        .select(_columns)
        .eq('post_id', postId)
        .isFilter('parent_id', null);

    if (cursor != null) query = _applyCursor(query, cursor);

    return _fetch(query, limit);
  }

  @override
  Future<List<PostCommentDto>> getReplies({
    required String parentId,
    required int limit,
    CommentCursor? cursor,
  }) async {
    var query = _client.from(_source).select(_columns).eq('parent_id', parentId);

    if (cursor != null) query = _applyCursor(query, cursor);

    return _fetch(query, limit);
  }

  /// 오래된 순이므로 커서 비교가 `gt` 다. 피드(`lt`)와 방향만 다르다.
  PostgrestFilterBuilder<List<Map<String, dynamic>>> _applyCursor(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query,
    CommentCursor cursor,
  ) {
    final createdAt = cursor.createdAt.toUtc().toIso8601String();
    // (created_at, id) 사전식 비교. 같은 시각에 두 댓글이 들어와도 순서가
    // 정해지고 경계에서 중복·누락이 생기지 않는다.
    return query.or(
      'created_at.gt.$createdAt,'
      'and(created_at.eq.$createdAt,id.gt.${cursor.id})',
    );
  }

  Future<List<PostCommentDto>> _fetch(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query,
    int limit,
  ) async {
    final rows = await query
        .order('created_at', ascending: true)
        .order('id', ascending: true)
        .limit(limit);

    return rows.map(PostCommentDto.fromJson).toList();
  }

  @override
  Future<CreatedComment?> addComment({
    required String postId,
    String? parentId,
    required String content,
  }) async {
    if (_client.auth.currentUser == null) return null;

    // author_id 는 보내지 않는다. DB 의 default auth.uid() 가 채운다.
    // returning 으로 서버가 정하는 값만 받고, 본문·작성자는 호출부가 채운다.
    // content 는 SELECT GRANT 에서 빠져 있으므로 여기에 넣을 수 없다.
    final row = await _client
        .from('post_comments')
        .insert({
          'post_id': postId,
          'parent_id': ?parentId,
          'content': content,
        })
        .select('id, created_at')
        .single();

    return (
      id: row['id'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  @override
  Future<bool?> deleteComment(String commentId) async {
    if (_client.auth.currentUser == null) return null;

    // deleted_at 을 직접 UPDATE 할 수는 없다. UPDATE 의 SELECT 정책이 새 행에도
    // 적용되기 때문이다. 삭제 경로는 security definer 함수 하나뿐이다.
    final deleted = await _client.rpc<dynamic>(
      'soft_delete_post_comment',
      params: {'comment_id': commentId},
    );
    return deleted == true;
  }
}
