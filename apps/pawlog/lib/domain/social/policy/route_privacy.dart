import 'dart:math' as math;

import '../../walk/entity/geo_point.dart';
import '../../walk/policy/route_preview.dart';

/// 두 점 사이 거리(m).
typedef GeoDistance = double Function(GeoPoint a, GeoPoint b);

/// 공유 경로의 앞뒤를 잘라 집 위치를 감춘다(plan 결정 4).
///
/// 산책은 대개 집에서 시작해 집에서 끝난다. 두 단계로 버린다.
///
/// 1. 출발점 · 도착점에서 **걸은 거리(누적)** 로 [defaultMeters] 안의 앞뒤 점.
/// 2. 남은 점 가운데 원래 출발점 · 도착점에서 **직선 거리** 로 [defaultMeters] 안인 점.
///
/// 누적 거리만으로는 부족하다 — 집 앞을 맴돌거나 중간에 집 앞을 다시 지나가면 누적은
/// 150 m 를 넘어도 그 점은 집 바로 옆이다. 그래서 직선 거리로 한 번 더 거른다.
/// (그래도 남은 선의 방향은 집 쪽을 가리킬 수 있다 — history.md 의 넘긴 항목.)
abstract final class RoutePrivacy {
  static const defaultMeters = 150.0;

  /// 앞뒤 [meters] 안(경계 포함)의 점과 출발점 · 도착점에서 직선 [meters] 안(경계 포함)의
  /// 점을 버리고 [RoutePreview.maxPoints] 개 이하로 줄인다.
  /// 남은 점이 2개 미만이면 선이 안 되므로 빈 목록 — 경로 없이 공유한다.
  static List<GeoPoint> trim(
    List<GeoPoint> points, {
    double meters = defaultMeters,
    GeoDistance distance = haversineMeters,
  }) {
    if (points.length < 2) return const [];

    // fromStart[i] = 처음부터 i 번째 점까지 걸은 거리.
    final fromStart = List<double>.filled(points.length, 0);
    for (var i = 1; i < points.length; i++) {
      fromStart[i] = fromStart[i - 1] + distance(points[i - 1], points[i]);
    }
    final total = fromStart.last;
    final home = points.first;
    final end = points.last;

    final kept = [
      for (var i = 0; i < points.length; i++)
        if (fromStart[i] > meters &&
            total - fromStart[i] > meters &&
            distance(home, points[i]) > meters &&
            distance(end, points[i]) > meters)
          points[i],
    ];
    if (kept.length < 2) return const [];
    return RoutePreview.downsamplePoints(kept);
  }

  static const _earthRadiusMeters = 6371008.8;

  /// 하버사인 거리(m). 산책 규모에선 충분히 정확하다.
  static double haversineMeters(GeoPoint a, GeoPoint b) {
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(b.lat - a.lat);
    final dLng = rad(b.lng - a.lng);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.lat)) *
            math.cos(rad(b.lat)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusMeters * math.asin(math.min(1, math.sqrt(h)));
  }
}
