import 'package:injectable/injectable.dart';

import '../location/place_lookup.dart';
import '../location/place_source.dart';
import 'photo_meta.dart';

/// 사진 EXIF 좌표 → 장소 이름(스펙 §4 메타데이터). 모델에는 이름만 간다 — 좌표는 여기서 끝난다.
@lazySingleton
class PhotoPlaceNames {
  PhotoPlaceNames(this._namer);

  final PlaceNamer _namer;

  /// 서로 다른 좌표를 이만큼만 묻는다(지오코딩 요청을 아낀다).
  static const maxLookups = 4;

  /// 소수 셋째 자리(약 100m)까지 같은 좌표는 한 번만 묻는다.
  static const _precision = 1000;

  /// 이름 없음 · 오프라인 · 실패는 빼고, 같은 이름은 한 번만(처음 나온 순서). 던지지 않는다.
  Future<List<String>> namesFor(Iterable<PhotoMeta?> metas) async {
    final cells = <(int, int)>{};
    final points = <(double, double)>[];
    for (final meta in metas) {
      final lat = meta?.lat;
      final lng = meta?.lng;
      if (lat == null || lng == null) continue;
      final cell = ((lat * _precision).round(), (lng * _precision).round());
      if (!cells.add(cell)) continue;
      points.add((lat, lng));
      if (points.length >= maxLookups) break;
    }
    final names = <String>{};
    for (final (lat, lng) in points) {
      try {
        if (await _namer.nameFor(lat, lng) case PlaceNamed(
          :final name,
        ) when name.trim().isNotEmpty) {
          names.add(name.trim());
        }
      } catch (_) {
        // 이 사진의 장소는 뺀다.
      }
    }
    return names.toList();
  }
}
