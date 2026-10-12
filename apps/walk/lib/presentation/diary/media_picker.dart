import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

import '../../domain/diary/entity/entry_media.dart';
import '../../domain/diary/entity/media_limits.dart';
import '../lock/media_pick_guard.dart';

/// 고른 사진 · 영상 원본.
typedef PickedMedia = ({String path, MediaKind kind});

/// `image_picker` 래퍼. 앨범 · 카메라로 나가는 동안 [MediaPickGuard] 를 켜 두어
/// 돌아왔을 때 일기가 다시 잠기지 않는다. 압축은 `MediaStore` 가 하므로 원본을 그대로 받는다.
@lazySingleton
class MediaPicker {
  MediaPicker(MediaPickGuard guard) : this.withPicker(guard, ImagePicker());

  @visibleForTesting
  MediaPicker.withPicker(this._guard, this._picker);

  final MediaPickGuard _guard;
  final ImagePicker _picker;

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
