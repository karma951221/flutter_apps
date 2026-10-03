import 'package:feature_walk/feature_walk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(List<GeoPoint> points, {Color color = Colors.green}) => Center(
  child: SizedBox(
    width: 100,
    height: 100,
    child: CustomPaint(
      key: const Key('preview'),
      painter: RoutePreviewPainter(points, color: color),
    ),
  ),
);

const _line = [
  GeoPoint(lat: 37.5, lng: 127),
  GeoPoint(lat: 37.51, lng: 127.01),
  GeoPoint(lat: 37.5, lng: 127.02),
];

RenderObject _render(WidgetTester tester) =>
    tester.renderObject(find.byKey(const Key('preview')));

void main() {
  testWidgets('점이 없으면 아무것도 그리지 않는다', (tester) async {
    await tester.pumpWidget(_host(const []));

    expect(tester.takeException(), isNull);
    expect(_render(tester), paintsNothing);
  });

  testWidgets('점이 있으면 경로를 그린다', (tester) async {
    await tester.pumpWidget(_host(_line));

    expect(tester.takeException(), isNull);
    expect(_render(tester), paints..path(color: Colors.green));
  });

  testWidgets('점이 하나여도 예외 없이 그린다', (tester) async {
    await tester.pumpWidget(_host(const [GeoPoint(lat: 37.5, lng: 127)]));

    expect(tester.takeException(), isNull);
    expect(_render(tester), paints..circle());
  });

  test('shouldRepaint 는 점 목록과 색을 비교한다', () {
    const base = RoutePreviewPainter(_line, color: Colors.green);

    expect(
      base.shouldRepaint(const RoutePreviewPainter(_line, color: Colors.green)),
      isFalse,
    );
    expect(
      base.shouldRepaint(const RoutePreviewPainter(_line, color: Colors.red)),
      isTrue,
    );
    expect(
      base.shouldRepaint(const RoutePreviewPainter([], color: Colors.green)),
      isTrue,
    );
  });
}
