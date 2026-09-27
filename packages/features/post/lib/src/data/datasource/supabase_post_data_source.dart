import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:core/core.dart';
import '../../domain/entity/post_draft.dart';
import '../../domain/entity/post_update.dart';
import '../dto/post_dto.dart';
import 'post_data_source.dart';

@LazySingleton(as: PostDataSource)
class SupabasePostDataSource implements PostDataSource {
  SupabasePostDataSource(this._client, this._ids, this._images);

  final SupabaseClient _client;
  final IdGenerator _ids;
  final ImageStorage _images;

  static const _bucket = 'post-images';

  /// `trade_result` 는 임베드에 별칭을 붙여 피드 뷰의 jsonb 와 **같은 키**로
  /// 받는다. 그래야 두 DTO 가 같은 JSON 을 읽고, 카드 위젯이 하나로 끝난다.
  /// 판을 붙이지 않았으면 이 키가 통째로 null 이다.
  static const _columns =
      'id, author_id, content, created_at, updated_at, '
      'post_images(id, url, width, height, sort_order), '
      'trade_result:trade_sessions('
      'session_id:id, symbol:revealed_symbol, '
      'start_day:revealed_start_day, end_day:revealed_end_day, '
      'return_pct, buy_hold_return_pct, max_drawdown_pct, trade_count)';

  @override
  Future<PostDto> getPost(String postId) async {
    // 중첩 리소스는 기본 정렬이 없다. 피드 뷰(sort_order 정렬)와 같은 순서를
    // 내려주려면 referencedTable 로 명시해야 한다.
    final row = await _client
        .from('posts')
        .select(_columns)
        .eq('id', postId)
        .order('sort_order', referencedTable: 'post_images', ascending: true)
        .single();
    return PostDto.fromJson(row);
  }

  @override
  Future<PostDto?> createPost(PostDraft draft) async {
    // 경로에 쓸 사용자 id 는 저장소가 세션에서 읽는다. 여기서는 로그인 여부만 본다.
    if (_client.auth.currentUser == null) return null;

    // 판을 붙일 때는 이미지가 없어도 RPC 로 간다. `trade_session_id` 에는 INSERT
    // GRANT 가 없어서(apps/trader/docs/schema.md §5) 직접 insert 는 42501 로 막힌다.
    if (draft.images.isEmpty && draft.tradeSessionId == null) {
      // author_id 는 보내지 않는다. DB 의 default auth.uid() 가 채운다.
      final row = await _client
          .from('posts')
          .insert({'content': draft.content})
          .select('id')
          .single();
      return getPost(row['id'] as String);
    }

    return getPost(await _createViaRpc(draft));
  }

  /// 이미지를 먼저 올리고, 마지막에 게시물 행을 만든다.
  ///
  /// 순서가 핵심이다. 게시물을 먼저 만들면 업로드 도중 실패했을 때 이미지 없는
  /// 유령 게시물이 남고, 재시도하면 게시물이 두 번 생긴다. 행 생성은
  /// `create_post_with_images` 한 번(= 트랜잭션 하나)으로 끝낸다.
  ///
  /// Storage 는 그 트랜잭션 밖이므로, 실패하면 올린 객체를 best-effort 로 지운다.
  ///
  /// 판만 붙이고 이미지가 없는 게시물도 이 경로로 온다 — 그때 업로드 반복문은
  /// 한 번도 돌지 않고 `images: []` 로 RPC 만 부른다.
  Future<String> _createViaRpc(PostDraft draft) async {
    // 폴더 이름은 게시물 id 일 필요가 없다 — Storage 정책이 보는 것은 첫 조각(사용자
    // id)뿐이고, 그건 저장소가 붙인다. 게시물 id 는 아직 없으므로 클라이언트에서
    // 만든 UUID 를 쓴다.
    final folder = _ids.newId();
    final uploaded = <String>[];

    try {
      final images = <Map<String, dynamic>>[];
      for (var index = 0; index < draft.images.length; index++) {
        final image = draft.images[index];
        final url = await _images.upload(
          bucket: _bucket,
          bytes: image.bytes,
          contentType: image.contentType,
          extension: image.extension,
          folder: folder,
          name: '$index',
        );
        final path = ImageStorage.objectPathFromPublicUrl(
          bucket: _bucket,
          publicUrl: url,
        );
        if (path != null) uploaded.add(path);
        images.add({
          'url': url,
          'width': image.width,
          'height': image.height,
          'sort_order': index,
        });
      }

      // 판이 없을 때는 인자를 아예 보내지 않는다. 함수의 default null 이 같은
      // 결과를 내므로, 기존 작성 경로가 보내던 요청을 그대로 둔다.
      final postId = await _client.rpc(
        'create_post_with_images',
        params: {
          'content': draft.content,
          'images': images,
          if (draft.tradeSessionId != null)
            'trade_session_id': draft.tradeSessionId,
        },
      );
      return postId as String;
    } catch (_) {
      await _images.removePaths(bucket: _bucket, paths: uploaded);
      rethrow;
    }
  }

  @override
  Future<PostDto?> updatePost(String postId, PostUpdate update) async {
    if (_client.auth.currentUser == null) return null;

    final row = await _client
        .from('posts')
        .update({'content': update.content})
        .eq('id', postId)
        .select(_columns)
        .order('sort_order', referencedTable: 'post_images', ascending: true)
        .single();
    return PostDto.fromJson(row);
  }

  @override
  Future<bool?> deletePost(String postId) async {
    if (_client.auth.currentUser == null) return null;

    // 소프트 삭제가 끝나면 post_images 행이 사라지고 조회 정책도 게시물을
    // 가리므로, 지울 객체 경로는 **먼저** 읽어둔다.
    final paths = await _imageObjectPaths(postId);

    // deleted_at 을 직접 UPDATE 할 수는 없다. PostgreSQL 이 UPDATE 의 SELECT 정책을
    // 새 행에도 적용해서, 삭제 표시를 한 행이 자기 조회 정책에 걸리기 때문이다.
    // 삭제 경로는 security definer 함수 하나뿐이다. apps/trader/docs/schema.md §6 참고.
    final deleted = await _client.rpc(
      'soft_delete_post',
      params: {'post_id': postId},
    );
    if (deleted != true) return false;

    // 게시물은 이미 숨겨졌다. 객체 정리에 실패해도 삭제는 성공이다.
    await _images.removePaths(bucket: _bucket, paths: paths);
    return true;
  }

  Future<List<String>> _imageObjectPaths(String postId) async {
    try {
      final rows = await _client
          .from('post_images')
          .select('url')
          .eq('post_id', postId);
      final paths = <String>[];
      for (final row in rows) {
        final path = ImageStorage.objectPathFromPublicUrl(
          bucket: _bucket,
          publicUrl: row['url'] as String,
        );
        if (path != null) paths.add(path);
      }
      return paths;
    } catch (_) {
      return const [];
    }
  }
}
