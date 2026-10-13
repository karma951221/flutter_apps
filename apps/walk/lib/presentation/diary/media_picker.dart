import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/diary/entity/entry_media.dart';
import '../../domain/diary/entity/media_limits.dart';
import '../lock/media_pick_guard.dart';

/// 고른 사진 · 영상 원본.
typedef PickedMedia = ({String path, MediaKind kind});

/// `image_picker` 래퍼. 앨범 · 카메라로 나가는 동안 [MediaPickGuard] 를 켜 두어
/// 돌아왔을 때 일기가 다시 잠기지 않는다. 압축은 `MediaStore` 가 하므로 원본을 그대로 받는다.
///
/// Android 의 `image_picker` 는 고른 앨범 파일을 GPS EXIF 째로 앱 캐시 폴더에 통째로
/// 복사해 두고 지우지 않는다. 가져오기가 끝나면 [release] 로 그 복사본을 지운다.
@lazySingleton
class MediaPicker {
  MediaPicker(MediaPickGuard guard)
    : this.withPicker(guard, ImagePicker(), cacheDir: getTemporaryDirectory);

  @visibleForTesting
  MediaPicker.withPicker(
    this._guard,
    this._picker, {
    required Future<Directory> Function() cacheDir,
  }) : _cacheDir = cacheDir;

  final MediaPickGuard _guard;
  final ImagePicker _picker;

  /// 앱 캐시 폴더(`getTemporaryDirectory`). 이 안에 있는 고른 파일만 지운다.
  final Future<Directory> Function() _cacheDir;

  /// 가져오기(성공이든 실패든)가 끝난 [picked] 중 앱 캐시 폴더 **안**의 복사본을 지우고,
  /// 그래서 비게 된 하위 폴더도 지운다. 캐시 밖(앨범 원본)은 건드리지 않는다.
  /// 정리 실패는 삼킨다 — 가져오기 결과를 바꾸지 않는다.
  Future<void> release(List<PickedMedia> picked) async {
    if (picked.isEmpty) return;
    final String cache;
    try {
      cache = _normalize((await _cacheDir()).path);
    } catch (_) {
      return;
    }
    for (final p in picked) {
      final path = _normalize(p.path);
      if (!_isWithin(cache, path)) continue;
      try {
        final file = File(path);
        if (file.existsSync()) await file.delete();
        final parent = file.parent;
        if (_isWithin(cache, _normalize(parent.path)) &&
            parent.listSync().isEmpty) {
          await parent.delete();
        }
      } on FileSystemException catch (_) {
        // 이미 지워졌거나 다른 파일이 남은 폴더 — 둔다.
      }
    }
  }

  /// `..` · `.` 을 풀고 끝의 `/` 를 뗀다.
  static String _normalize(String path) {
    final normalized = Uri.file(path).normalizePath().toFilePath();
    return normalized.length > 1 && normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
  }

  /// [path] 가 [dir] 의 하위인지(같은 폴더는 아니다).
  static bool _isWithin(String dir, String path) => path.startsWith('$dir/');

  /// 앨범에서 사진 · 영상을 여러 개, 최대 [limit] 개 고른다. 취소하면 빈 목록.
  Future<List<PickedMedia>> pickGallery({required int limit}) async {
    final files = await _guard.run(
      () => _picker.pickMultipleMedia(limit: limit, requestFullMetadata: false),
    );
    return [for (final f in files) (path: f.path, kind: kindOf(f))];
  }

  Future<List<PickedMedia>> takePhoto() async {
    final file = await _guard.run(
      () => _picker.pickImage(
        source: ImageSource.camera,
        requestFullMetadata: false,
      ),
    );
    return [if (file != null) (path: file.path, kind: MediaKind.photo)];
  }

  /// 길이 제한을 넘는 녹화는 `MediaStore.importVideo` 가 거절한다.
  Future<List<PickedMedia>> recordVideo() async {
    final file = await _guard.run(
      () => _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: MediaLimits.maxVideo,
      ),
    );
    return [if (file != null) (path: file.path, kind: MediaKind.video)];
  }

  static const _videoExtensions = {
    'mp4',
    'mov',
    'm4v',
    '3gp',
    '3g2',
    'mkv',
    'webm',
    'avi',
  };

  /// MIME 이 있으면 그것으로, 없으면(Android 앨범은 자주 비어 있다) 확장자로 가른다.
  @visibleForTesting
  static MediaKind kindOf(XFile file) {
    final mime = file.mimeType;
    if (mime != null) {
      return mime.startsWith('video/') ? MediaKind.video : MediaKind.photo;
    }
    final dot = file.path.lastIndexOf('.');
    final ext = dot < 0 ? '' : file.path.substring(dot + 1).toLowerCase();
    return _videoExtensions.contains(ext) ? MediaKind.video : MediaKind.photo;
  }
}
