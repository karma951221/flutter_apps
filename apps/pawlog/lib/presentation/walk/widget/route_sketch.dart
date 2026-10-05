import 'package:flutter/material.dart';

import '../../../domain/walk/entity/geo_point.dart';
import '../../feed/widget/route_preview_painter.dart';
import '../../theme/pawlog_theme.dart';
import 'route_draw.dart';

/// 타일 없는 경로 그림 — `mapBg` 바탕에 남색 테두리 · 연두 선. 피드 항목과 저장 폼이 쓴다.
///
/// 점이 2개 미만이면 선 대신 지도 아이콘 하나를 둔다. [animate] 면 처음 보일 때 선이
/// 출발점부터 1.6초에 걸쳐 그려진다([RouteDraw]).
class RouteSketch extends StatelessWidget {
  const RouteSketch({required this.points, this.animate = false, super.key});

  final List<GeoPoint> points;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = PawlogColors.of(context);
    return ColoredBox(
      color: colors.mapBg,
      child: points.length < 2
          ? Center(child: Icon(Icons.map_outlined, color: colors.textMuted))
          : RouteDraw(
              animate: animate,
              builder: (context, progress) => CustomPaint(
                painter: RoutePreviewPainter(
                  points,
                  color: colors.accent,
                  casingColor: colors.routeCasing,
                  progress: progress,
                ),
              ),
            ),
    );
  }
}
