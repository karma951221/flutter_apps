import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entity/feed_post_draft.dart';
import '../../domain/entity/feed_post_update.dart';
import '../dto/feed_post_dto.dart';
import 'feed_data_source.dart';

@LazySingleton(as: FeedDataSource)
class SupabaseFeedDataSource implements FeedDataSource {
  SupabaseFeedDataSource(this._client);

  final SupabaseClient _client;

  static const _feedPostColumns =
      'id, author_id, content, created_at, updated_at';

  @override
  Future<List<FeedPostDto>> getFeedPosts({
    required int limit,
    required int offset,
  }) async {
    final rows = await _client
        .from('feed_posts')
        .select(_feedPostColumns)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + limit - 1);
    return rows.map(FeedPostDto.fromJson).toList();
  }

  @override
  Future<FeedPostDto> getFeedPost(String postId) async {
    final row = await _client
        .from('feed_posts')
        .select(_feedPostColumns)
        .eq('id', postId)
        .single();
    return FeedPostDto.fromJson(row);
  }

  @override
  Future<FeedPostDto?> createFeedPost(FeedPostDraft draft) async {
    if (_client.auth.currentUser == null) return null;

    final row = await _client
        .from('feed_posts')
        .insert({'content': draft.content})
        .select(_feedPostColumns)
        .single();
    return FeedPostDto.fromJson(row);
  }

  @override
  Future<FeedPostDto?> updateFeedPost(
    String postId,
    FeedPostUpdate update,
  ) async {
    if (_client.auth.currentUser == null) return null;

    final row = await _client
        .from('feed_posts')
        .update({'content': update.content})
        .eq('id', postId)
        .select(_feedPostColumns)
        .single();
    return FeedPostDto.fromJson(row);
  }

  @override
  Future<FeedPostDto?> deleteFeedPost(String postId) async {
    if (_client.auth.currentUser == null) return null;

    final row = await _client
        .from('feed_posts')
        .delete()
        .eq('id', postId)
        .select(_feedPostColumns)
        .single();
    return FeedPostDto.fromJson(row);
  }
}
