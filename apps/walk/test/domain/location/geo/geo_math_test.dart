import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/location/geo/geo_math.dart';

void main() {
  test('haversine City Hall to Gwanghwamun is about 1070m', () {
    final d = haversineMeters(37.5663, 126.9779, 37.5759, 126.9768);
    expect(d, closeTo(1070, 20));
  });

  test('gridKey rounds to 3 decimals', () {
    expect(gridKey(37.56612, 126.97803), '37.566,126.978');
  });

  test('gridKey keeps 3 decimals for negative longitude', () {
    expect(gridKey(40.7128, -74.006), '40.713,-74.006');
  });
}
