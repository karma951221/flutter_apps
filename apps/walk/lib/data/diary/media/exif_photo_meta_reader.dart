import 'dart:io';

import 'package:exif/exif.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/diary/draft/photo_meta.dart';
import '../../../domain/diary/media/photo_meta_reader.dart';

/// `exif`(순수 Dart)로 원본의 `DateTimeOriginal` 만 읽는다(GPS 는 읽지 않는다). 파일을 고치거나 값을 저장하지 않는다.
///
/// 촬영 시각은 EXIF 관례대로 기기 시간대의 벽시계 시각으로 읽는다(시간대 태그는 보지 않는다).
@LazySingleton(as: PhotoMetaReader)
class ExifPhotoMetaReader implements PhotoMetaReader {
  const ExifPhotoMetaReader();

  @override
  Future<PhotoMeta?> read(String path) async {
    try {
      final tags = await readExifFromFile(File(path), details: false);
      final takenAt = _dateTime(tags['EXIF DateTimeOriginal']?.printable);
      return takenAt == null ? null : PhotoMeta(takenAt: takenAt);
    } catch (_) {
      return null;
    }
  }

  static final _exifDate = RegExp(
    r'^(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})',
  );

  /// `yyyy:MM:dd HH:mm:ss`. 0 으로 채운 값 · 범위를 벗어난 값은 null.
  static DateTime? _dateTime(String? raw) {
    final m = _exifDate.firstMatch(raw?.trim() ?? '');
    if (m == null) return null;
    final [y, mo, d, h, mi, s] = [
      for (var i = 1; i <= 6; i++) int.parse(m[i]!),
    ];
    if (y == 0 || mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    if (h > 23 || mi > 59 || s > 59) return null;
    final value = DateTime(y, mo, d, h, mi, s);
    // 2월 30일처럼 넘어가면 버린다.
    if (value.month != mo || value.day != d) return null;
    return value;
  }
}
