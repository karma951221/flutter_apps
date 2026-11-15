import '../draft/photo_meta.dart';

/// 고른 원본 사진에서 촬영 시각 · 좌표를 읽는다(스펙 §4 메타데이터).
///
/// 압축 사본은 EXIF 가 지워지므로 원본 경로로 — `MediaPicker.release` 가 원본 복사본을 지우기 **전에** 부른다.
abstract interface class PhotoMetaReader {
  /// 읽을 것이 없거나 어떤 실패든 null. 던지지 않는다.
  Future<PhotoMeta?> read(String path);
}
