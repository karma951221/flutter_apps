import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:latlong2/latlong.dart';
import 'package:pawlog/domain/walk/entity/geo_point.dart';
import 'package:pawlog/presentation/feed/widget/route_preview_painter.dart';
import 'package:pawlog/presentation/theme/pawlog_theme.dart';
import 'package:pawlog/presentation/walk/widget/route_map.dart';
import 'package:pawlog/presentation/walk/widget/route_sketch.dart';

import '../../../support/stub_tile_provider.dart';

const _points = [
  GeoPoint(lat: 37.5, lng: 127),
  GeoPoint(lat: 37.501, lng: 127.001),
  GeoPoint(lat: 37.502, lng: 127),
];

/// `pumpApp` 은 `pumpAndSettle` 로 연출을 끝까지 돌려 버려서 쓰지 않는다.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool disableAnimations = false,
}) => tester.pumpWidget(
  MaterialApp(
    theme: PawlogTheme.light(),
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: child),
    ),
  ),
);

double _sketchProgress(WidgetTester tester) =>
    (tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(RouteSketch),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as RoutePreviewPainter)
        .progress;

List<LatLng> _drawn(WidgetTester tester) => tester
    .widget<PolylineLayer>(find.byType(PolylineLayer))
    .polylines
    .single
    .points;

void main() {
  group('RouteMap.partialRoute', () {
    const a = LatLng(37.5, 127);
    const b = LatLng(37.502, 127);
    const c = LatLng(37.504, 127);

    test('0 은 출발점만, 1 은 전체다', () {
      expect(RouteMap.partialRoute(const [a, b, c], 0), [a]);
      expect(RouteMap.partialRoute(const [a, b, c], 1), [a, b, c]);
    });

    test('중간이면 마지막 구간을 길이 비율에서 끊는다', () {
      final half = RouteMap.partialRoute(const [a, b, c], 0.5);
      expect(half.length, 2);
      expect(half.last.latitude, closeTo(37.502, 1e-9));

      final quarter = RouteMap.partialRoute(const [a, b, c], 0.25);
      expect(quarter.length, 2);
      expect(quarter.last.latitude, closeTo(37.501, 1e-9));
    });
  });

  group('RouteSketch(animate)', () {
    testWidgets('처음 보이면 1.6초에 걸쳐 0 에서 1 까지 그린다', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 200,
          height: 150,
          child: RouteSketch(points: _points, animate: true),
        ),
      );

      expect(_sketchProgress(tester), 0);
      await tester.pump(PawlogMotion.routeDraw ~/ 2);
      expect(_sketchProgress(tester), allOf(greaterThan(0), lessThan(1)));
      await tester.pump(PawlogMotion.routeDraw ~/ 2);
      expect(_sketchProgress(tester), 1);
    });

    testWidgets('애니메이션 줄이기면 처음부터 완성된 선이다', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 200,
          height: 150,
          child: RouteSketch(points: _points, animate: true),
        ),
        disableAnimations: true,
      );

      expect(_sketchProgress(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('animate 가 거짓이면(피드) 처음부터 완성된 선이다', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 200,
          height: 150,
          child: RouteSketch(points: _points),
        ),
      );

      expect(_sketchProgress(tester), 1);
    });
  });

  group('RouteMap(animateDraw)', () {
    final route = [for (final p in _points) LatLng(p.lat, p.lng)];

    setUp(() => getIt.registerFactory<TileProvider>(StubTileProvider.new));
    tearDown(getIt.reset);

    testWidgets('출발점에서 시작해 1.6초 뒤 전체 경로와 도착 점이 된다', (tester) async {
      await _pump(tester, const RouteMap(points: _points, animateDraw: true));

      expect(_drawn(tester), [route.first]);
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
        1,
      );

      await tester.pump(PawlogMotion.routeDraw);
      expect(_drawn(tester), route);
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length,
        2,
      );
    });

    testWidgets('애니메이션 줄이기면 처음부터 전체 경로다', (tester) async {
      await _pump(
        tester,
        const RouteMap(points: _points, animateDraw: true),
        disableAnimations: true,
      );

      expect(_drawn(tester), route);
    });
  });
}
