import 'dart:math';

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

  static const _bucket = 'post-images';

  /// 공개 URL 에서 객체 경로를 잘라낼 기준. Storage 의 공개 URL 은
  /// `.../storage/v1/object/public/{bucket}/{path}` 모양이다.
  static const _publicUrlMarker = '/object/public/$_bucket/';

  static final _random = Random.secure();

  static const _columns =
      'id, author_id, content, created_at, updated_at, '
      'post_images(id, url, width, height, sort_order)';

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
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    if (draft.images.isEmpty) {
      // author_id 는 보내지 않는다. DB 의 default auth.uid() 가 채운다.
      final row = await _client
          .from('posts')
          .insert({'content': draft.content})
          .select('id')
          .single();
      return getPost(row['id'] as String);
    }

    return getPost(await _createWithImages(draft, userId));
  }

  /// 이미지를 먼저 올리고, 마지막에 게시물 행을 만든다.
  ///
  /// 순서가 핵심이다. 게시물을 먼저 만들면 업로드 도중 실패했을 때 이미지 없는
  /// 유령 게시물이 남고, 재시도하면 게시물이 두 번 생긴다. 행 생성은
  /// `create_post_with_images` 한 번(= 트랜잭션 하나)으로 끝낸다.
  ///
  /// Storage 는 그 트랜잭션 밖이므로, 실패하면 올린 객체를 best-effort 로 지운다.
  Future<String> _createWithImages(PostDraft draft, String userId) async {
    final storage = _client.storage.from(_bucket);

    // 폴더 이름은 게시물 id 일 필요가 없다 — Storage 정책이 보는 것은 첫 조각뿐이다.
    // 게시물 id 는 아직 없으므로 클라이언트에서 만든 UUID 를 쓴다.
    final folder = '$userId/${_uuidV4()}';
    final uploaded = <String>[];

    try {
      final images = <Map<String, dynamic>>[];
      for (var index = 0; index < draft.images.length; index++) {
        final image = draft.images[index];
        final path = '$folder/$index.${image.extension}';
        await storage.uploadBinary(
          path,
          image.bytes,
          fileOptions: FileOptions(contentType: image.contentType),
        );
        uploaded.add(path);
        images.add({
          'url': storage.getPublicUrl(path),
          'width': image.width,
          'height': image.height,
          'sort_order': index,
        });
      }

      final postId = await _client.rpc(
        'create_post_with_images',
        params: {'content': draft.content, 'images': images},
      );
      return postId as String;
    } catch (_) {
      await _removeObjects(uploaded);
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
    // 삭제 경로는 security definer 함수 하나뿐이다. docs/schema.md §6 참고.
    final deleted = await _client.rpc(
      'soft_delete_post',
      params: {'post_id': postId},
    );
    if (deleted != true) return false;

    // 게시물은 이미 숨겨졌다. 객체 정리에 실패해도 삭제는 성공이다.
    await _removeObjects(paths);
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
        final path = _objectPath(row['url'] as String);
        if (path != null) paths.add(path);
      }
      return paths;
    } catch (_) {
      return const [];
    }
  }

  /// 공개 URL → 버킷 안의 객체 경로. 모양이 다르면 null.
  String? _objectPath(String url) {
    final marker = url.indexOf(_publicUrlMarker);
    if (marker < 0) return null;
    var encoded = url.substring(marker + _publicUrlMarker.length);
    final query = encoded.indexOf('?');
    if (query >= 0) encoded = encoded.substring(0, query);
    if (encoded.isEmpty) return null;
    return Uri.decodeComponent(encoded);
  }

  Future<void> _removeObjects(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _client.storage.from(_bucket).remove(paths);
    } catch (_) {
      // best-effort. 남은 객체는 게시물과 이어지지 않으므로 노출되지 않는다.
    }
  }

  /// 의존성을 늘리지 않기 위한 최소 UUID v4 생성기.
  static String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
