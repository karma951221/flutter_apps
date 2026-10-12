import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/presentation/diary/media_picker.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';

/// 고르는 동안 잠금 예외가 켜져 있었는지 기록한다.
class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker(this.guard);

  final MediaPickGuard guard;
  final List<bool> guardedCalls = [];
  int? lastLimit;
  List<XFile> picked = const [];
  XFile? captured;

  @override
  Future<List<XFile>> pickMultipleMedia({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async {
    guardedCalls.add(guard.active);
    lastLimit = limit;
    return picked;
  }

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    guardedCalls.add(guard.active);
    return captured;
  }

  @override
  Future<XFile?> pickVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async {
    guardedCalls.add(guard.active);
    return captured;
  }
}

void main() {
  late MediaPickGuard guard;
  late _FakeImagePicker images;
  late MediaPicker picker;

  setUp(() {
    guard = MediaPickGuard();
    images = _FakeImagePicker(guard);
    picker = MediaPicker.withPicker(guard, images);
  });

  test('앨범 고르기는 잠금 예외 안에서, 남은 칸만큼, 종류를 붙여 돌려준다', () async {
    images.picked = [
      XFile('/a/IMG_1.JPG'),
      XFile('/a/clip.mp4'),
      XFile('/a/x', mimeType: 'video/quicktime'),
      XFile('/a/photo.heic'),
    ];

    final picked = await picker.pickGallery(limit: 4);

    expect(images.guardedCalls, [true]);
    expect(guard.active, isFalse);
    expect(images.lastLimit, 4);
    expect(picked.map((p) => (p.path, p.kind)), [
      ('/a/IMG_1.JPG', MediaKind.photo),
      ('/a/clip.mp4', MediaKind.video),
      ('/a/x', MediaKind.video),
      ('/a/photo.heic', MediaKind.photo),
    ]);
  });

  test('카메라 사진 · 영상도 잠금 예외 안에서, 취소하면 빈 목록', () async {
    images.captured = XFile('/c/shot.jpg');
    expect(await picker.takePhoto(), [
      (path: '/c/shot.jpg', kind: MediaKind.photo),
    ]);

    images.captured = XFile('/c/rec.mp4');
    expect(await picker.recordVideo(), [
      (path: '/c/rec.mp4', kind: MediaKind.video),
    ]);

    images.captured = null;
    expect(await picker.takePhoto(), isEmpty);
    expect(images.guardedCalls, [true, true, true]);
  });
}
