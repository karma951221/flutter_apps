import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

/// 카메라가 [path] 에 원본을 남긴 것처럼 돌려준다.
class _FakeCameraPicker extends ImagePicker {
  _FakeCameraPicker(this.path);

  final String? path;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => path == null ? null : XFile(path!);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImagePickerService.captureImage', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('capture_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('취소하면 null 이다', () async {
      final service = ImagePickerService.withPicker(_FakeCameraPicker(null));

      expect(await service.captureImage(), isNull);
    });

    test('준비가 실패해도 카메라 원본 임시 파일을 지운다', () async {
      // 이미지가 아닌 바이트라 디코드에서 실패한다 — 실패 경로에서도 원본이 남지 않아야 한다.
      final original = File('${dir.path}/camera.jpg')
        ..writeAsBytesSync([1, 2, 3]);
      final service = ImagePickerService.withPicker(
        _FakeCameraPicker(original.path),
      );

      await expectLater(service.captureImage(), throwsA(anything));
      expect(original.existsSync(), isFalse);
    });
  });
}
