import 'package:feature_walk/feature_walk.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  test('64개 이하로 줄이고 첫 점과 마지막 점을 보존한다', () {
    final points = [for (var i = 0; i < 1000; i++) trackPoint(37 + i / 1000)];

    final result = RoutePreview.downsample(points);

    expect(result.length, lessThanOrEqualTo(RoutePreview.maxPoints));
    expect(result.first, points.first.point);
    expect(result.last, points.last.point);
  });

  test('64개 이하면 그대로 둔다', () {
    final points = [for (var i = 0; i < 10; i++) trackPoint(37 + i / 1000)];

    expect(RoutePreview.downsample(points), [for (final p in points) p.point]);
  });

  test('encode/decode 왕복', () {
    const points = [
      GeoPoint(lat: 37.5, lng: 127.1),
      GeoPoint(lat: 37.6, lng: 127),
    ];

    expect(RoutePreview.decode(RoutePreview.encode(points)), points);
  });

  test('null 은 빈 목록', () {
    expect(RoutePreview.decode(null), isEmpty);
    expect(RoutePreview.decode(''), isEmpty);
  });
}
