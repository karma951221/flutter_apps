import 'dart:io';

/// 고른 사진 · 영상을 앱 전용 사본으로 줄인다. 원본은 읽기만 한다.
abstract interface class MediaProcessor {
  /// [source] 를 [target] 에 긴 변 1600 · JPEG 85 · EXIF 제거로 쓴다. 원본보다 키우지 않는다.
  Future<({int width, int height})> compressPhoto(File source, File target);

  /// 길이 확인(ms). 읽지 못하면 예외.
  Future<int> videoDurationMs(File source);

  /// 720p 로 [target] 에 쓰고 썸네일을 [thumb] 에 쓴다.
  ///
  /// 겹쳐 불러도 된다 — 구현이 앱 전체에서 한 번에 하나씩 차례로 처리한다.
  /// 앞 호출이 실패해도 다음 호출은 처리된다.
  Future<({int width, int height, int durationMs})> compressVideo(
    File source,
    File target,
    File thumb,
  );
}
