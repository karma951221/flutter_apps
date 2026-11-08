import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/location/entity/location_point.dart';
import 'package:walk/domain/location/entity/record_mode.dart';
import 'package:walk/domain/location/usecase/track_analyzer.dart';

final _t0 = DateTime.utc(2026, 11, 8, 9);

LocationPoint _p(
  DateTime at, {
  double lat = 37.5663,
  double lng = 126.9779,
  RecordMode mode = RecordMode.normal,
  bool still = false,
}) => LocationPoint(
  recordedAt: at,
  lat: lat,
  lng: lng,
  mode: mode,
  stillStart: still,
);

/// 1분 간격 [n]점, 위도 0.0001도(약 11m)씩 흔들린다.
List<LocationPoint> _stayPoints(DateTime start, int n) => [
  for (var i = 0; i < n; i++)
    _p(
      start.add(Duration(minutes: i)),
      lat: 37.5663 + (i.isEven ? 0 : 0.0001),
    ),
];

void main() {
  final analyzer = TrackAnalyzer();

  test('points within 100m for 10 minutes form one stay', () {
    final t = analyzer.analyze(_stayPoints(_t0, 11));
    expect(t.stays.length, 1);
    expect(t.stays.single.duration, const Duration(minutes: 10));
    expect(t.stays.single.pointCount, 11);
  });

  test('9 minutes is not a stay', () {
    final t = analyzer.analyze(_stayPoints(_t0, 10));
    expect(t.stays, isEmpty);
  });

  test('gap over 30 minutes splits segments', () {
    final t = analyzer.analyze([
      ..._stayPoints(_t0, 3),
      ..._stayPoints(_t0.add(const Duration(minutes: 33)), 3),
    ]);
    expect(t.segments.length, 2);
  });

  test('mode change splits segments', () {
    final t = analyzer.analyze([
      for (var i = 0; i < 3; i++) _p(_t0.add(Duration(minutes: i))),
      for (var i = 3; i < 6; i++)
        _p(_t0.add(Duration(minutes: i)), mode: RecordMode.dense),
    ]);
    expect(t.segments.length, 2);
    expect(t.segments[0].mode, RecordMode.normal);
    expect(t.segments[1].mode, RecordMode.dense);
  });

  test('stay spanning midnight is clipped to day bounds', () {
    final from = DateTime.utc(2026, 11, 8);
    final to = DateTime.utc(2026, 11, 8, 23, 59, 59, 999);
    final t = analyzer.analyze(
      _stayPoints(DateTime.utc(2026, 11, 8, 23, 50), 31),
      clipFrom: from,
      clipTo: to,
    );
    expect(t.stays.single.end, to);
    expect(t.stays.single.start, DateTime.utc(2026, 11, 8, 23, 50));
  });

  test('empty input gives empty track', () {
    expect(analyzer.analyze([]).isEmpty, isTrue);
  });

  test('still gap within radius is one stay', () {
    final t = analyzer.analyze([
      _p(_t0, still: true),
      _p(DateTime.utc(2026, 11, 8, 17), lat: 37.5665),
    ]);
    expect(t.segments.length, 1);
    expect(t.stays.single.start, _t0);
    expect(t.stays.single.end, DateTime.utc(2026, 11, 8, 17));
  });

  test('still gap then far point ends stay without line', () {
    final next = DateTime.utc(2026, 11, 8, 17);
    final t = analyzer.analyze([
      _p(_t0, still: true),
      _p(next, lat: 37.5663 + 0.018), // 약 2km
    ]);
    expect(t.segments.length, 2);
    expect(t.stays.single.start, _t0);
    expect(t.stays.single.end, next.subtract(const Duration(milliseconds: 1)));
  });

  test('gap without stillStart still splits', () {
    final t = analyzer.analyze([
      _p(_t0),
      _p(_t0.add(const Duration(minutes: 31))),
    ]);
    expect(t.stays, isEmpty);
    expect(t.segments.length, 2);
  });
}
