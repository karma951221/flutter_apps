import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/transit/entity/station_hit.dart';
import 'package:walk/domain/transit/entity/transit_point.dart';

void main() {
  test('TransitPoint json roundtrip', () {
    const p = TransitPoint(
      lat: 37.5,
      lng: 127.03,
      label: '집',
      source: TransitPointSource.home,
    );
    expect(TransitPoint.fromJson(p.toJson()), p);
  });

  test('TransitPoint fromJson rejects broken', () {
    expect(TransitPoint.fromJson(null), isNull);
    expect(TransitPoint.fromJson('x'), isNull);
    expect(TransitPoint.fromJson({'lat': 1, 'lng': 2, 'label': 'a'}), isNull);
    expect(
      TransitPoint.fromJson({
        'lat': 1,
        'lng': 2,
        'label': 'a',
        'source': 'nope',
      }),
      isNull,
    );
    expect(
      TransitPoint.fromJson({
        'lat': 'x',
        'lng': 2,
        'label': 'a',
        'source': 'home',
      }),
      isNull,
    );
  });

  test('cacheKey rounds to 4 decimals', () {
    const p = TransitPoint(
      lat: 37.123456,
      lng: 127.987654,
      label: 'a',
      source: TransitPointSource.address,
    );
    expect(p.cacheKey, '37.1235,127.9877');
  });

  test('StationHit json roundtrip', () {
    const hit = StationHit(
      name: '강남',
      kind: StationKind.subway,
      lat: 37.4979,
      lng: 127.0276,
      detail: '2호선',
    );
    expect(StationHit.fromJson(hit.toJson()), hit);
    expect(StationHit.fromJson({'name': 'x'}), isNull);
  });
}
