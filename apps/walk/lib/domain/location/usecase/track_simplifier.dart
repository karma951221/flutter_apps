import 'dart:math' as math;

import '../entity/location_point.dart';

/// Douglas–Peucker 로 점을 줄인다. 처음 · 끝은 항상 남긴다.
/// 거리는 위도 기준 등장방형 근사 미터.
List<LocationPoint> simplify(
  List<LocationPoint> points, {
  required double toleranceM,
}) {
  if (points.length <= 2) return points;
  const mPerDeg = 111320.0;
  final cosLat = math.cos(points.first.lat * math.pi / 180);
  final xs = [for (final p in points) p.lng * mPerDeg * cosLat];
  final ys = [for (final p in points) p.lat * mPerDeg];

  double distToLine(int i, int a, int b) {
    final dx = xs[b] - xs[a];
    final dy = ys[b] - ys[a];
    final len2 = dx * dx + dy * dy;
    var t = 0.0;
    if (len2 != 0) {
      t = (((xs[i] - xs[a]) * dx + (ys[i] - ys[a]) * dy) / len2).clamp(
        0.0,
        1.0,
      );
    }
    final px = xs[a] + t * dx;
    final py = ys[a] + t * dy;
    return math.sqrt(math.pow(xs[i] - px, 2) + math.pow(ys[i] - py, 2));
  }

  final keep = List<bool>.filled(points.length, false);
  keep[0] = keep[points.length - 1] = true;
  final stack = <(int, int)>[(0, points.length - 1)];
  while (stack.isNotEmpty) {
    final (a, b) = stack.removeLast();
    var maxD = 0.0;
    var idx = -1;
    for (var i = a + 1; i < b; i++) {
      final d = distToLine(i, a, b);
      if (d > maxD) {
        maxD = d;
        idx = i;
      }
    }
    if (idx != -1 && maxD > toleranceM) {
      keep[idx] = true;
      stack.add((a, idx));
      stack.add((idx, b));
    }
  }
  return [
    for (var i = 0; i < points.length; i++)
      if (keep[i]) points[i],
  ];
}
