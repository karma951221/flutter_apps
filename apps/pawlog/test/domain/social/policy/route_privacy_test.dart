import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/domain/social/policy/route_privacy.dart';
import 'package:pawlog/domain/walk/entity/geo_point.dart';
import 'package:pawlog/domain/walk/policy/route_preview.dart';

/// 위도 값을 그대로 미터로 읽는 직선 거리 — 경계를 정확히 시험하려고 주입한다.
double _planar(GeoPoint a, GeoPoint b) => (a.lat - b.lat).abs();

/// 0 m 에서 [length] m 까지 [step] m 간격의 직선 경로.
List<GeoPoint> _line(int length, {int step = 10}) => [
  for (var m = 0; m <= length; m += step) GeoPoint(lat: m.toDouble(), lng: 0),
];

List<double> _meters(List<GeoPoint> points) => [for (final p in points) p.lat];

void main() {
  test('앞뒤 150 m 안(정확히 150 m 포함)의 점을 버리고 가운데를 남긴다', () {
    final trimmed = RoutePrivacy.trim(_line(1000), distance: _planar);

    expect(trimmed.first.lat, 160);
    expect(trimmed.last.lat, 840);
    expect(_meters(trimmed), isNot(contains(150)));
    expect(_meters(trimmed), isNot(contains(850)));
  });

  test('누적 거리로 잰다 — 시작점으로 되돌아오는 경로도 150 m 걸은 뒤부터 남는다', () {
    // 0 → 100 → 0 → 100 ... 왕복. 직선 거리는 늘 100 m 이하지만 누적은 늘어난다.
    final points = [
      for (var i = 0; i < 20; i++) GeoPoint(lat: i.isEven ? 0 : 100, lng: 0),
    ];

    final trimmed = RoutePrivacy.trim(points, distance: _planar);

    // 누적 0,100,200,...,1900 — 앞에서 200 m(세 번째 점)부터, 뒤에서 1700 m 까지.
    expect(trimmed, hasLength(16));
  });

  test('정확히 300 m 경로는 남는 점이 없어 빈 목록이다', () {
    expect(RoutePrivacy.trim(_line(300), distance: _planar), isEmpty);
  });

  test('300 m 보다 짧으면 빈 목록이다', () {
    expect(RoutePrivacy.trim(_line(280), distance: _planar), isEmpty);
  });

  test('한 점만 남으면 선이 안 되므로 빈 목록이다', () {
    // 0..320 — 160 m 한 점만 양쪽에서 150 m 를 넘는다.
    expect(RoutePrivacy.trim(_line(320), distance: _planar), isEmpty);
    expect(_meters(RoutePrivacy.trim(_line(330), distance: _planar)), [
      160,
      170,
    ]);
  });

  test('빈 경로 · 한 점은 빈 목록이다', () {
    expect(RoutePrivacy.trim(const []), isEmpty);
    expect(RoutePrivacy.trim(const [GeoPoint(lat: 37, lng: 127)]), isEmpty);
  });

  test('남은 경로는 64개 이하로 줄이고 남은 처음 · 끝을 보존한다', () {
    final trimmed = RoutePrivacy.trim(_line(10000, step: 1), distance: _planar);

    expect(trimmed.length, RoutePreview.maxPoints);
    expect(trimmed.first.lat, 151);
    expect(trimmed.last.lat, 9849);
  });

  test('meters 를 바꿀 수 있다', () {
    final trimmed = RoutePrivacy.trim(
      _line(100),
      meters: 20,
      distance: _planar,
    );

    expect(trimmed.first.lat, 30);
    expect(trimmed.last.lat, 70);
  });

  test('기본 거리는 하버사인 — 위도 1도는 약 111 km', () {
    final meters = RoutePrivacy.haversineMeters(
      const GeoPoint(lat: 37, lng: 127),
      const GeoPoint(lat: 38, lng: 127),
    );

    expect(meters, closeTo(111195, 50));
  });

  test('실제 좌표로 1 km 직선이면 가운데 약 700 m 가 남는다', () {
    // 위도 0.0001도 ≈ 11.1 m 간격으로 90개 ≈ 990 m.
    final points = [
      for (var i = 0; i < 90; i++) GeoPoint(lat: 37 + i * 0.0001, lng: 127),
    ];

    final trimmed = RoutePrivacy.trim(points);

    expect(
      RoutePrivacy.haversineMeters(points.first, trimmed.first),
      greaterThan(150),
    );
    expect(
      RoutePrivacy.haversineMeters(trimmed.last, points.last),
      greaterThan(150),
    );
  });
}
