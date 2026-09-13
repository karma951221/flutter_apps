import 'package:core/core.dart';
import 'package:feature_commute/feature_commute.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const near = GeoPoint(lat: 37.4979, lng: 127.0276);
  const medium = GeoPoint(lat: 37.5547, lng: 126.9706);
  const far = GeoPoint(lat: 37.6584, lng: 126.8320);
  late FakeTransitRouteRepository repository;

  setUp(() => repository = FakeTransitRouteRepository());

  Future<List<TransitRoute>> search(GeoPoint destination) async {
    final result = await repository.search(
      origin: near,
      destination: destination,
    );
    return (result as Ok<List<TransitRoute>>).value;
  }

  test('subway, bus, best 순서로 세 경로를 반환한다', () async {
    final routes = await search(medium);

    expect(routes.map((route) => route.mode), [
      TransitMode.subway,
      TransitMode.bus,
      TransitMode.best,
    ]);
  });

  test('같은 입력은 같은 결과를 만든다', () async {
    expect(await search(medium), await search(medium));
  });

  test('거리가 먼 목적지는 모든 모드에서 더 오래 걸린다', () async {
    final mediumRoutes = await search(medium);
    final farRoutes = await search(far);

    for (var i = 0; i < mediumRoutes.length; i++) {
      expect(farRoutes[i].duration, greaterThan(mediumRoutes[i].duration));
    }
  });

  test('각 leg의 분 합은 전체 소요 시간과 같다', () async {
    final routes = await search(far);

    for (final route in routes) {
      expect(
        route.legs.fold<int>(0, (sum, leg) => sum + leg.minutes),
        route.duration.inMinutes,
      );
    }
  });
}
