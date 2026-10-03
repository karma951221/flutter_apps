import 'dart:convert';

import '../entity/geo_point.dart';
import '../entity/walk_track_point.dart';

/// 목록 카드용으로 줄인 경로. 전체 경로는 별도 테이블에 둔다.
class RoutePreview {
  const RoutePreview._();

  static const maxPoints = 64;

  /// 균등 간격으로 [maxPoints] 개 이하로 줄이되 처음과 끝은 항상 남긴다.
  static List<GeoPoint> downsample(List<WalkTrackPoint> points) {
    if (points.length <= maxPoints) {
      return [for (final p in points) p.point];
    }
    final last = points.length - 1;
    return [
      for (var i = 0; i < maxPoints; i++)
        points[(i * last / (maxPoints - 1)).round()].point,
    ];
  }

  static String encode(List<GeoPoint> points) => jsonEncode([
    for (final p in points) [p.lat, p.lng],
  ]);

  /// 깨진 값이면 빈 목록을 준다. 행 하나의 프리뷰가 잘못됐다고 피드 스트림
  /// 전체가 끊기면 안 된다 — 카드가 썸네일 없이 뜨는 쪽이 낫다.
  static List<GeoPoint> decode(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return [
        for (final e in list)
          GeoPoint(
            lat: ((e as List<dynamic>)[0] as num).toDouble(),
            lng: (e[1] as num).toDouble(),
          ),
      ];
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    } on RangeError {
      return const [];
    }
  }
}
