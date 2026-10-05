import 'package:flutter/material.dart';

import '../../../domain/walk/entity/geo_point.dart';
import '../../feed/widget/route_preview_painter.dart';
import '../../theme/pawlog_theme.dart';

/// 타일 없는 경로 그림 — `mapBg` 바탕에 남색 테두리 · 연두 선. 피드 항목과 저장 폼이 쓴다.
///
/// 점이 2개 미만이면 선 대신 지도 아이콘 하나를 둔다.
class RouteSketch extends StatelessWidget {
  const RouteSketch({required this.points, super.key});

  final List<GeoPoint> points;

  @override
  Widget build(BuildContext context) {
    final colors = PawlogColors.of(context);
    return ColoredBox(
      color: colors.mapBg,
      child: points.length < 2
          ? Center(child: Icon(Icons.map_outlined, color: colors.textMuted))
          : CustomPaint(
              painter: RoutePreviewPainter(
                points,
                color: colors.accent,
                casingColor: colors.routeCasing,
              ),
            ),
    );
  }
}
