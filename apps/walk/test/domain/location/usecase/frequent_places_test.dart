import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/location/entity/stay.dart';
import 'package:walk/domain/location/usecase/frequent_places.dart';

Stay _s(double lat, double lng, {int minutes = 20}) => Stay(
  start: DateTime.utc(2026, 11, 1, 9),
  end: DateTime.utc(2026, 11, 1, 9, minutes),
  lat: lat,
  lng: lng,
  pointCount: 5,
);

void main() {
  test('orders by visits', () {
    final r = frequentPlaces([
      _s(37.5001, 127.0001),
      _s(37.6001, 127.1001),
      _s(37.5002, 127.0002),
      _s(37.5003, 127.0003),
      _s(37.6002, 127.1002),
    ]);
    expect(r.map((p) => p.visits), [3, 2]);
    expect(r.first.gridKey, '37.500,127.000');
  });

  test('ties broken by larger total', () {
    final r = frequentPlaces([
      _s(37.5, 127.0, minutes: 15),
      _s(37.6, 127.1, minutes: 60),
    ]);
    expect(r.first.gridKey, '37.600,127.100');
    expect(r.first.total, const Duration(minutes: 60));
  });

  test('limits to 10', () {
    final r = frequentPlaces([
      for (var i = 0; i < 15; i++) _s(37.0 + i * 0.01, 127.0),
    ]);
    expect(r.length, 10);
  });
}
