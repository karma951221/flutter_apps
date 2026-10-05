import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/domain/walk/entity/geo_point.dart';
import 'package:pawlog/presentation/feed/widget/route_preview_painter.dart';
import 'package:pawlog/presentation/theme/pawlog_theme.dart';
import 'package:pawlog/presentation/walk/widget/route_sketch.dart';

import '../../../support/pump_app.dart';

/// 4:3 상자(400×300)에 [points] 를 그리고 상자 · 그려진 경로의 경계를 돌려준다.
Future<(Size, Rect)> _draw(WidgetTester tester, List<GeoPoint> points) async {
  await pumpApp(
    tester,
    Center(
      child: SizedBox(
        width: 400,
        height: 300,
        child: RouteSketch(points: points),
      ),
    ),
  );
  final box = tester.renderObject<RenderBox>(
    find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is RoutePreviewPainter,
    ),
  );
  Rect? bounds;
  expect(
    box,
    paints..something((method, args) {
      if (method != #drawPath) return false;
      bounds = (args[0] as Path).getBounds();
      return true;
    }),
  );
  return (box.size, bounds!);
}

/// 선 테두리 바깥으로도 [PawlogSpacing.lg] 가 남는 여백.
const _pad = PawlogSpacing.lg + PawlogSize.routeCasing / 2;

void main() {
  testWidgets('가로로 긴 경로는 좌우 여백까지 맞추고 위아래 가운데에 놓인다', (tester) async {
    final (size, route) = await _draw(tester, const [
      GeoPoint(lat: 37.5, lng: 127),
      GeoPoint(lat: 37.501, lng: 127.005),
      GeoPoint(lat: 37.5, lng: 127.01),
    ]);

    expect(route.left, closeTo(_pad, 0.01));
    expect(route.right, closeTo(size.width - _pad, 0.01));
    expect(route.top, greaterThan(_pad));
    expect(route.center.dy, closeTo(size.height / 2, 0.01));
    expect(route.center.dx, closeTo(size.width / 2, 0.01));
  });

  testWidgets('세로로 긴 경로는 위아래 여백까지 맞추고 좌우 가운데에 놓인다', (tester) async {
    final (size, route) = await _draw(tester, const [
      GeoPoint(lat: 37.5, lng: 127),
      GeoPoint(lat: 37.505, lng: 127.001),
      GeoPoint(lat: 37.51, lng: 127),
    ]);

    expect(route.top, closeTo(_pad, 0.01));
    expect(route.bottom, closeTo(size.height - _pad, 0.01));
    expect(route.left, greaterThan(_pad));
    expect(route.center.dx, closeTo(size.width / 2, 0.01));
    expect(route.center.dy, closeTo(size.height / 2, 0.01));
  });
}
