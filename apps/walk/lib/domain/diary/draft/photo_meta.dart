import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_meta.freezed.dart';

/// 고른 원본 사진의 EXIF 에서 읽은 촬영 시각 · 좌표. 메모리에만 들고 저장하지 않는다.
@Freezed(toStringOverride: false)
class PhotoMeta with _$PhotoMeta {
  @override
  final DateTime? takenAt;
  @override
  final double? lat;
  @override
  final double? lng;

  const PhotoMeta({this.takenAt, this.lat, this.lng});

  bool get hasLocation => lat != null && lng != null;

  @override
  String toString() =>
      'PhotoMeta(takenAt: ${takenAt != null}, location: $hasLocation)';
}

extension PhotoMetaRange on Iterable<PhotoMeta?> {
  /// 촬영 시각이 있는 사진 중 가장 이른 · 늦은 시각. 하나도 없으면 null.
  ({DateTime from, DateTime to})? get takenRange {
    DateTime? from;
    DateTime? to;
    for (final at in map((m) => m?.takenAt).nonNulls) {
      if (from == null || at.isBefore(from)) from = at;
      if (to == null || at.isAfter(to)) to = at;
    }
    if (from == null || to == null) return null;
    return (from: from, to: to);
  }
}
