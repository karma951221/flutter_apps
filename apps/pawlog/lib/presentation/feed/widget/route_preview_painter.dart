import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../domain/walk/entity/geo_point.dart';
import '../../theme/pawlog_theme.dart';

/// 경로 점들을 타일 없이 폴리라인으로만 그리는 미리보기. 네트워크를 쓰지 않는다.
///
/// 점들의 경계 상자를 비율을 유지한 채 여백 안에 맞추고 가로 · 세로 모두 가운데에 둔다.
/// 점이 없으면 아무것도 그리지 않는다.
/// [casingColor] 가 있으면 그 색 9 테두리 위에 [color] 5 선을 얹는다(design.md 경로 선) —
/// 연두는 밝은 바탕 위 대비가 약해 늘 남색 테두리와 함께 쓴다.
class RoutePreviewPainter extends CustomPainter {
  const RoutePreviewPainter(
    this.points, {
    required this.color,
    this.casingColor,
    this.progress = 1,
  });

  final List<GeoPoint> points;
  final Color color;
  final Color? casingColor;

  /// 0 ~ 1 — 출발점부터 경로 길이의 이 비율까지만 그린다(경로 그리기 연출).
  final double progress;

  static const _strokeWidth = PawlogSize.routeStroke;
  static const _casingWidth = PawlogSize.routeCasing;

  /// 경로를 맞출 때 가장자리에서 띄우는 폭 — 선 테두리(반 폭) 바깥으로도 [PawlogSpacing.lg]
  /// 가 남는다. 이전 14 는 테두리 4.5 를 빼면 9.5 만 남아 선이 상자에 붙어 보였다.
  static const _inset = PawlogSpacing.lg + _casingWidth / 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final area = Rect.fromLTWH(
      _inset,
      _inset,
      math.max(0, size.width - _inset * 2),
      math.max(0, size.height - _inset * 2),
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

    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final casing = casingColor;

    if (points.length == 1) {
      final center = project(points.first);
      if (casing != null) {
        canvas.drawCircle(
          center,
          _casingWidth / 2,
          stroke(casing, 0)..style = PaintingStyle.fill,
        );
      }
      canvas.drawCircle(
        center,
        _strokeWidth / 2,
        stroke(color, 0)..style = PaintingStyle.fill,
      );
      return;
    }
    final full = Path()
      ..moveTo(project(points.first).dx, project(points.first).dy);
    for (final p in points.skip(1)) {
      final o = project(p);
      full.lineTo(o.dx, o.dy);
    }
    final path = progress >= 1 ? full : _head(full, progress.clamp(0, 1));
    if (casing != null) canvas.drawPath(path, stroke(casing, _casingWidth));
    canvas.drawPath(path, stroke(color, _strokeWidth));
  }

  /// [path] 의 앞쪽 [fraction] 만큼.
  static Path _head(Path path, double fraction) {
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var remaining = total * fraction;
    final head = Path();
    for (final metric in metrics) {
      if (remaining <= 0) break;
      final length = math.min(remaining, metric.length);
      head.addPath(metric.extractPath(0, length), Offset.zero);
      remaining -= length;
    }
    return head;
  }

  @override
  bool shouldRepaint(RoutePreviewPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      casingColor != oldDelegate.casingColor ||
      !listEquals(points, oldDelegate.points);
}
