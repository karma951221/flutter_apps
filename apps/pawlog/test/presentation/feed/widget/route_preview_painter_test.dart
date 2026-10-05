import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/domain/walk/entity/geo_point.dart';
import 'package:pawlog/presentation/feed/widget/route_preview_painter.dart';

Widget _host(
  List<GeoPoint> points, {
  Color color = Colors.green,
  Color? casingColor,
}) => Center(
  child: SizedBox(
    width: 100,
    height: 100,
    child: CustomPaint(
      key: const Key('preview'),
      painter: RoutePreviewPainter(
        points,
        color: color,
        casingColor: casingColor,
      ),
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

  testWidgets('테두리 색이 있으면 굵은 테두리 위에 가는 선을 얹는다', (tester) async {
    await tester.pumpWidget(_host(_line, casingColor: Colors.indigo));

    expect(
      _render(tester),
      paints
        ..path(color: Colors.indigo, strokeWidth: 9)
        ..path(color: Colors.green, strokeWidth: 5),
    );
  });

  testWidgets('점이 하나여도 예외 없이 그린다', (tester) async {
    await tester.pumpWidget(_host(const [GeoPoint(lat: 37.5, lng: 127)]));

    expect(tester.takeException(), isNull);
    expect(_render(tester), paints..circle());
  });

  test('shouldRepaint 는 점 목록 · 색 · 테두리 색을 비교한다', () {
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
    expect(
      base.shouldRepaint(
        const RoutePreviewPainter(
          _line,
          color: Colors.green,
          casingColor: Colors.indigo,
        ),
      ),
      isTrue,
    );
  });
}
