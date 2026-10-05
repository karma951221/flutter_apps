import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/domain/walk/entity/geo_point.dart';
import 'package:pawlog/presentation/walk/widget/route_map.dart';

import '../../../support/pump_app.dart';
import '../../../support/stub_tile_provider.dart';

void main() {
  var resolved = 0;

  setUp(() {
    resolved = 0;
    getIt.registerFactory<TileProvider>(() {
      resolved++;
      return StubTileProvider();
    });
  });
  tearDown(getIt.reset);

  testWidgets('점이 늘어 다시 그려도 TileProvider 는 지도당 한 번만 받는다', (tester) async {
    const a = GeoPoint(lat: 37.5, lng: 127);
    const b = GeoPoint(lat: 37.501, lng: 127.001);

    Widget map(List<GeoPoint> points) =>
        Scaffold(body: RouteMap(points: points, follow: true));

    await pumpApp(tester, map(const [a]));
    await pumpApp(tester, map(const [a, b]));

    expect(resolved, 1);
  });
}
