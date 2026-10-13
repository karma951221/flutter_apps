import 'dart:io';

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
  late Directory sandbox;
  late Directory cache;

  setUp(() {
    guard = MediaPickGuard();
    images = _FakeImagePicker(guard);
    sandbox = Directory.systemTemp.createTempSync('media_picker_test');
    cache = Directory('${sandbox.path}/cache')..createSync();
    picker = MediaPicker.withPicker(guard, images, cacheDir: () async => cache);
  });

  tearDown(() => sandbox.deleteSync(recursive: true));

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

  group('release', () {
    File write(String path) => File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);

    test('앱 캐시 안에 복사된 원본은 지우고 비게 된 폴더도 지운다', () async {
      final copy = write('${cache.path}/3f2a/IMG_1.jpg');
      final clip = write('${cache.path}/clip.mp4');

      await picker.release([
        (path: copy.path, kind: MediaKind.photo),
        (path: clip.path, kind: MediaKind.video),
      ]);

      expect(copy.existsSync(), isFalse);
      expect(Directory('${cache.path}/3f2a').existsSync(), isFalse);
      expect(clip.existsSync(), isFalse);
      expect(cache.existsSync(), isTrue);
    });

    test('앱 캐시 밖(앨범 원본)은 건드리지 않는다', () async {
      final original = write('${sandbox.path}/DCIM/IMG_1.jpg');
      // 이름만 캐시로 시작하는 옆 폴더도 밖이다.
      final sibling = write('${sandbox.path}/cache2/IMG_2.jpg');
      final escaping = write('${sandbox.path}/IMG_3.jpg');

      await picker.release([
        (path: original.path, kind: MediaKind.photo),
        (path: sibling.path, kind: MediaKind.photo),
        (path: '${cache.path}/../IMG_3.jpg', kind: MediaKind.photo),
      ]);

      expect(original.existsSync(), isTrue);
      expect(sibling.existsSync(), isTrue);
      expect(escaping.existsSync(), isTrue);
    });

    test('이미 없는 파일 · 캐시 폴더를 못 찾아도 던지지 않는다', () async {
      await picker.release([
        (path: '${cache.path}/gone.jpg', kind: MediaKind.photo),
      ]);

      final failing = MediaPicker.withPicker(
        guard,
        images,
        cacheDir: () => Future.error(const FileSystemException('no cache')),
      );
      final kept = write('${cache.path}/kept.jpg');
      await failing.release([(path: kept.path, kind: MediaKind.photo)]);
      expect(kept.existsSync(), isTrue);
    });
  });
}
