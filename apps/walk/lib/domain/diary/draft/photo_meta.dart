import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_meta.freezed.dart';

/// 고른 원본 사진의 EXIF 에서 읽은 촬영 시각(스펙 2026-11-15 §4 R-A5). 메모리에만 들고 저장하지 않는다.
/// 좌표는 읽지 않는다.
@freezed
class PhotoMeta with _$PhotoMeta {
  @override
  final DateTime? takenAt;

  const PhotoMeta({this.takenAt});
}

/// 촬영 시각이 지금과 이만큼 넘게 다르면 "찍은 시각으로" 칩을 보이고, 자동으로 잡힌 현재 위치를
/// 초안 재료에서 뺀다(R-A6).
const photoTakenFarThreshold = Duration(hours: 3);

/// [taken] 이 [now] 와 [photoTakenFarThreshold] 넘게 다른가(앞 · 뒤 모두).
bool takenFarFromNow(DateTime taken, DateTime now) =>
    taken.difference(now).abs() > photoTakenFarThreshold;

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
