import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entity/post_draft.dart';
import '../../domain/entity/post_update.dart';
import '../dto/post_dto.dart';
import 'post_data_source.dart';

@LazySingleton(as: PostDataSource)
class SupabasePostDataSource implements PostDataSource {
  SupabasePostDataSource(this._client);

  final SupabaseClient _client;

  static const _columns = 'id, author_id, content, created_at, updated_at';

  @override
  Future<PostDto> getPost(String postId) async {
    final row = await _client
        .from('posts')
        .select(_columns)
        .eq('id', postId)
        .single();
    return PostDto.fromJson(row);
  }

  @override
  Future<PostDto?> createPost(PostDraft draft) async {
    if (_client.auth.currentUser == null) return null;

    // author_id 는 보내지 않는다. DB 의 default auth.uid() 가 채운다.
    final row = await _client
        .from('posts')
        .insert({'content': draft.content})
        .select(_columns)
        .single();
    return PostDto.fromJson(row);
  }

  @override
  Future<PostDto?> updatePost(String postId, PostUpdate update) async {
    if (_client.auth.currentUser == null) return null;

    final row = await _client
        .from('posts')
        .update({'content': update.content})
        .eq('id', postId)
        .select(_columns)
        .single();
    return PostDto.fromJson(row);
  }

  @override
  Future<bool?> deletePost(String postId) async {
    if (_client.auth.currentUser == null) return null;

    // deleted_at 을 직접 UPDATE 할 수는 없다. PostgreSQL 이 UPDATE 의 SELECT 정책을
    // 새 행에도 적용해서, 삭제 표시를 한 행이 자기 조회 정책에 걸리기 때문이다.
    // 삭제 경로는 security definer 함수 하나뿐이다. docs/schema.md §6 참고.
    final deleted = await _client.rpc(
      'soft_delete_post',
      params: {'post_id': postId},
    );
    return deleted == true;
  }
}
