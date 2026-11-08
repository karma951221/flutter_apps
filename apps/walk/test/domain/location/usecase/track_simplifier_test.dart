import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/location/entity/location_point.dart';
import 'package:walk/domain/location/entity/record_mode.dart';
import 'package:walk/domain/location/usecase/track_simplifier.dart';

LocationPoint _p(int i, double lat, double lng) => LocationPoint(
  recordedAt: DateTime.utc(2026, 11, 8, 9).add(Duration(seconds: i)),
  lat: lat,
  lng: lng,
  mode: RecordMode.dense,
);

void main() {
  test('simplify keeps endpoints and drops points within tolerance', () {
    final line = [
      for (var i = 0; i < 100; i++) _p(i, 37.5, 127.0 + i * 0.0001),
    ];
    final r = simplify(line, toleranceM: 10);
    expect(r.length, 2);
    expect(r.first, line.first);
    expect(r.last, line.last);
  });

  test('simplify keeps a corner farther than tolerance', () {
    final pts = [
      _p(0, 37.5, 127.0),
      _p(1, 37.5, 127.001),
      _p(2, 37.5 + 0.0018, 127.002), // 약 200m 위
      _p(3, 37.5, 127.003),
      _p(4, 37.5, 127.004),
    ];
    final r = simplify(pts, toleranceM: 30);
    expect(r, contains(pts[2]));
    expect(r.first, pts.first);
    expect(r.last, pts.last);
  });

  test('two or fewer points are returned as is', () {
    final pts = [_p(0, 37.5, 127.0), _p(1, 37.6, 127.1)];
    expect(simplify(pts, toleranceM: 30), pts);
    expect(simplify([], toleranceM: 30), isEmpty);
  });
}
