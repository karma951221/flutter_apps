import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads normalised images to an authenticated user's own Storage prefix.
///
/// The caller supplies the bucket, the bytes and the encoding that produced
/// them: paths always start with the session user id, matching the Storage RLS
/// policies. Content-Type 과 확장자를 인자로 받는 이유는 인코딩 형식이
/// 플랫폼마다 다르기 때문이다 (Android WebP, 그 밖 JPEG).
@lazySingleton
class ImageUploader {
  ImageUploader(this._client);

  final SupabaseClient _client;

  Future<String> upload({
    required String bucket,
    required Uint8List bytes,
    required String contentType,
    required String extension,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StorageException('Not authenticated');

    final path = '$userId/${DateTime.now().microsecondsSinceEpoch}.$extension';
    final storage = _client.storage.from(bucket);
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: false),
    );
    return storage.getPublicUrl(path);
  }

  /// 공개 URL 로 가리켜지는 객체를 지운다. 실패는 삼킨다.
  ///
  /// 교체된 옛 이미지나 저장에 실패한 새 이미지를 치우는 용도라, 여기서 난
  /// 오류로 사용자의 저장 흐름을 되돌리지 않는다.
  Future<void> removeByPublicUrl({
    required String bucket,
    required String? publicUrl,
  }) async {
    final path = objectPathFromPublicUrl(bucket: bucket, publicUrl: publicUrl);
    if (path == null) return;
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (e) {
      debugPrint('[storage] $bucket/$path 삭제 실패: $e');
    }
  }

  /// 공개 URL 에서 버킷 안의 객체 경로를 뽑는다.
  ///
  /// 다른 버킷이나 외부 URL 이면 null 을 준다. 우리가 올린 적 없는 이미지를
  /// 지우려 들면 안 되기 때문이다.
  static String? objectPathFromPublicUrl({
    required String bucket,
    required String? publicUrl,
  }) {
    if (publicUrl == null) return null;
    final marker = '/object/public/$bucket/';
    final index = publicUrl.indexOf(marker);
    if (index < 0) return null;

    var path = publicUrl.substring(index + marker.length);
    final query = path.indexOf('?');
    if (query >= 0) path = path.substring(0, query);
    if (path.isEmpty) return null;

    return Uri.decodeComponent(path);
  }
}
