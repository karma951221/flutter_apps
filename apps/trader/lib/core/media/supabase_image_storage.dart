import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/mapper/supabase_error_mapper.dart';
import '../error/failure.dart';
import '../error/failure_code.dart';
import 'image_storage.dart';

/// [ImageStorage] 의 Supabase Storage 구현.
///
/// Supabase 타입은 여기서 끝난다 (규칙 ①). 업로드 실패는 [SupabaseErrorMapper]
/// 를 거쳐 [Failure] 로 바꿔 던지므로 (규칙 ④) 이 클래스를 쓰는 datasource ·
/// repository 는 SDK 예외를 다루지 않는다. repository 의 `guard` 는 이미
/// `on Failure` 를 그대로 통과시키므로 변환이 두 번 일어나지 않는다.
@LazySingleton(as: ImageStorage)
class SupabaseImageStorage implements ImageStorage {
  SupabaseImageStorage(this._client);

  final SupabaseClient _client;

  @override
  Future<String> upload({
    required String bucket,
    required Uint8List bytes,
    required String contentType,
    required String extension,
    String? folder,
    String? name,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const Failure.auth(
        message: '로그인이 필요합니다',
        code: 'not_authenticated',
        failureCode: FailureCode.authenticationRequired,
      );
    }

    // 경로의 첫 조각은 사용자 id 다. Storage 정책이 보는 것도 이 조각뿐이다.
    final fileName =
        '${name ?? DateTime.now().microsecondsSinceEpoch}.$extension';
    final prefix = folder == null ? userId : '$userId/$folder';
    final path = '$prefix/$fileName';

    final storage = _client.storage.from(bucket);
    try {
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: false),
      );
    } on Failure {
      rethrow;
    } catch (error) {
      throw SupabaseErrorMapper.map(error);
    }
    return storage.getPublicUrl(path);
  }

  @override
  Future<String> uploadToPath({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const Failure.auth(
        message: '로그인이 필요합니다',
        code: 'not_authenticated',
        failureCode: FailureCode.authenticationRequired,
      );
    }

    try {
      await _client.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );
    } on Failure {
      rethrow;
    } catch (error) {
      throw SupabaseErrorMapper.map(error);
    }
    // 비공개 버킷이라 공개 URL 이 없다. 저장하는 값도 화면이 받는 값도 경로다.
    return path;
  }

  @override
  Future<String> signedUrl({
    required String bucket,
    required String path,
    Duration expiresIn = const Duration(hours: 1),
  }) async {
    try {
      return await _client.storage
          .from(bucket)
          .createSignedUrl(path, expiresIn.inSeconds);
    } on Failure {
      rethrow;
    } catch (error) {
      throw SupabaseErrorMapper.map(error);
    }
  }

  @override
  Future<void> removeByPublicUrl({
    required String bucket,
    required String? publicUrl,
  }) {
    final path = ImageStorage.objectPathFromPublicUrl(
      bucket: bucket,
      publicUrl: publicUrl,
    );
    if (path == null) return Future.value();
    return removePaths(bucket: bucket, paths: [path]);
  }

  @override
  Future<void> removePaths({
    required String bucket,
    required List<String> paths,
  }) async {
    if (paths.isEmpty) return;
    try {
      await _client.storage.from(bucket).remove(paths);
    } catch (e) {
      // best-effort. 남은 객체는 어떤 행과도 이어지지 않으므로 노출되지 않는다.
      debugPrint('[storage] $bucket/${paths.join(', ')} 삭제 실패: $e');
    }
  }

  @override
  Future<void> removeAllForCurrentUser({required String bucket}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final paths = await _collectPaths(bucket, userId, _maxListDepth);
      await removePaths(bucket: bucket, paths: paths);
    } catch (e) {
      debugPrint('[storage] $bucket/$userId 전체 삭제 실패: $e');
    }
  }

  /// list() 는 한 단계만 보므로 폴더를 만나면 내려간다.
  ///
  /// 지금 구조에서 깊이는 avatars 가 1(`{uid}/x.webp`),
  /// post-images 가 2(`{uid}/{uuid}/{n}.webp`)다. 순환·이상 구조에 대비해
  /// 깊이에 상한을 둔다.
  static const _maxListDepth = 3;

  Future<List<String>> _collectPaths(
    String bucket,
    String prefix,
    int depth,
  ) async {
    if (depth <= 0) return const [];

    final entries = await _client.storage.from(bucket).list(path: prefix);
    final paths = <String>[];
    for (final entry in entries) {
      // 파일에는 메타데이터(id)가 있고 폴더에는 없다.
      if (entry.id != null) {
        paths.add('$prefix/${entry.name}');
      } else {
        paths.addAll(
          await _collectPaths(bucket, '$prefix/${entry.name}', depth - 1),
        );
      }
    }
    return paths;
  }
}
