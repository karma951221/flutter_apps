import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/geo_point.dart';

/// 경로 점들을 타일 없이 폴리라인으로만 그리는 미리보기. 네트워크를 쓰지 않는다.
///
/// 점들의 경계 상자를 비율을 유지한 채 캔버스에 맞춘다. 점이 없으면 아무것도 그리지 않는다.
class RoutePreviewPainter extends CustomPainter {
  const RoutePreviewPainter(this.points, {required this.color});

  final List<GeoPoint> points;
  final Color color;

  static const _strokeWidth = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final area = Rect.fromLTWH(
      AppSpacing.sm,
      AppSpacing.sm,
      math.max(0, size.width - AppSpacing.sm * 2),
      math.max(0, size.height - AppSpacing.sm * 2),
    );

    var minLat = points.first.lat;
    var maxLat = minLat;
    var minLng = points.first.lng;
    var maxLng = minLng;
    for (final p in points) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }
    // 경도 1도는 위도 1도보다 짧다(cos 위도). 보정 없이 그리면 동서로 늘어난
    // 모양이 된다 (⑦ 리뷰 F1).
    final lngScale = math.cos((minLat + maxLat) / 2 * math.pi / 180);
    final spanLat = maxLat - minLat;
    final spanLng = (maxLng - minLng) * lngScale;
    // 한 점이거나 한 직선 위여도 0 으로 나누지 않는다.
    final scale = math.min(
      spanLng == 0 ? double.infinity : area.width / spanLng,
      spanLat == 0 ? double.infinity : area.height / spanLat,
    );
    final usable = scale.isFinite ? scale : 0.0;
    final drawnWidth = spanLng * usable;
    final drawnHeight = spanLat * usable;
    final left = area.left + (area.width - drawnWidth) / 2;
    final top = area.top + (area.height - drawnHeight) / 2;

    Offset project(GeoPoint p) => Offset(
      left + (p.lng - minLng) * lngScale * usable,
      // 위도는 위쪽이 크다.
      top + (maxLat - p.lat) * usable,
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (points.length == 1) {
      canvas.drawCircle(
        project(points.first),
        _strokeWidth,
        paint..style = PaintingStyle.fill,
      );
      return;
    }
    final path = Path()
      ..moveTo(project(points.first).dx, project(points.first).dy);
    for (final p in points.skip(1)) {
      final o = project(p);
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(RoutePreviewPainter oldDelegate) =>
      color != oldDelegate.color || !listEquals(points, oldDelegate.points);
}
