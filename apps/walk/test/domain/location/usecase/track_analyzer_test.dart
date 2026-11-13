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
    _p(start.add(Duration(minutes: i)), lat: 37.5663 + (i.isEven ? 0 : 0.0001)),
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

  test('gap over 30 minutes to a far point splits segments', () {
    final t = analyzer.analyze([
      ..._stayPoints(_t0, 3),
      for (var i = 0; i < 3; i++)
        _p(_t0.add(Duration(minutes: 33 + i)), lat: 37.5663 + 0.018),
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

  test('gap without stillStart to a far point still splits', () {
    final t = analyzer.analyze([
      _p(_t0),
      _p(_t0.add(const Duration(minutes: 31)), lat: 37.5663 + 0.018),
    ]);
    expect(t.stays, isEmpty);
    expect(t.segments.length, 2);
  });

  test('gap without stillStart at the same spot is a stay (AR denied)', () {
    final t = analyzer.analyze([
      _p(DateTime.utc(2026, 11, 8, 8, 58)),
      _p(DateTime.utc(2026, 11, 8, 18, 1), lat: 37.5664),
    ]);
    expect(t.segments.length, 1);
    expect(t.stays.single.start, DateTime.utc(2026, 11, 8, 8, 58));
    expect(t.stays.single.end, DateTime.utc(2026, 11, 8, 18, 1));
  });

  test('stillStart then far point within 30 minutes still closes the stay', () {
    final next = DateTime.utc(2026, 11, 8, 9, 25);
    final t = analyzer.analyze([
      ..._stayPoints(_t0, 4), // 09:00~09:03
      _p(DateTime.utc(2026, 11, 8, 9, 3), lat: 37.5663, still: true),
      _p(next, lat: 37.5663 + 0.018),
    ]);
    expect(t.segments.length, 2);
    expect(t.stays.single.end, next.subtract(const Duration(milliseconds: 1)));
  });

  test('multi-point group ending in stillStart closes only the last stay', () {
    final next = DateTime.utc(2026, 11, 8, 11);
    final t = analyzer.analyze([
      ..._stayPoints(_t0, 13), // A: 09:00~09:12
      _p(DateTime.utc(2026, 11, 8, 9, 15), lat: 37.5663 + 0.009), // 짧은 외출
      _p(DateTime.utc(2026, 11, 8, 9, 18), lat: 37.5663 + 0.018),
      _p(DateTime.utc(2026, 11, 8, 9, 19), lat: 37.5663 + 0.018),
      _p(DateTime.utc(2026, 11, 8, 9, 20), lat: 37.5663 + 0.018, still: true),
      _p(next, lat: 37.5663 + 0.05),
    ]);
    expect(t.stays.length, 2);
    expect(t.stays.first.start, _t0);
    expect(t.stays.first.end, DateTime.utc(2026, 11, 8, 9, 12));
    expect(t.stays.last.start, DateTime.utc(2026, 11, 8, 9, 18));
    expect(t.stays.last.end, next.subtract(const Duration(milliseconds: 1)));
  });

  test('segment points outside the clip window are filtered', () {
    final from = DateTime.utc(2026, 11, 8, 9, 2);
    final to = DateTime.utc(2026, 11, 8, 9, 4);
    final t = analyzer.analyze(
      [
        ..._stayPoints(_t0, 6), // 09:00~09:05 (한 구간)
        ..._stayPoints(DateTime.utc(2026, 11, 8, 12), 3), // 창 밖 구간
      ],
      clipFrom: from,
      clipTo: to,
    );
    expect(t.segments.length, 1);
    expect(t.segments.single.points.map((p) => p.recordedAt.minute), [2, 3, 4]);
  });

  test('overnight still stay shows on both days, clipped to each', () {
    final points = [
      _p(DateTime.utc(2026, 11, 8, 19, 5), still: true),
      _p(DateTime.utc(2026, 11, 9, 7, 30), lat: 37.5663 + 0.018),
    ];
    final day1 = analyzer.analyze(
      points,
      clipFrom: DateTime.utc(2026, 11, 8),
      clipTo: DateTime.utc(2026, 11, 8, 23, 59, 59, 999),
    );
    expect(day1.stays.single.start, DateTime.utc(2026, 11, 8, 19, 5));
    expect(day1.stays.single.end, DateTime.utc(2026, 11, 8, 23, 59, 59, 999));
    final day2 = analyzer.analyze(
      points,
      clipFrom: DateTime.utc(2026, 11, 9),
      clipTo: DateTime.utc(2026, 11, 9, 23, 59, 59, 999),
    );
    expect(day2.stays.single.start, DateTime.utc(2026, 11, 9));
    expect(day2.stays.single.end, DateTime.utc(2026, 11, 9, 7, 29, 59, 999));
  });

  test('ongoing still stay is closed at openEnd', () {
    final now = DateTime.utc(2026, 11, 8, 15);
    final t = analyzer.analyze(
      [
        ..._stayPoints(DateTime.utc(2026, 11, 8, 8, 40), 3),
        _p(DateTime.utc(2026, 11, 8, 9, 3), lat: 37.5663 + 0.018, still: true),
      ],
      clipFrom: DateTime.utc(2026, 11, 8),
      clipTo: DateTime.utc(2026, 11, 8, 23, 59, 59, 999),
      openEnd: now,
    );
    expect(t.stays.single.start, DateTime.utc(2026, 11, 8, 9, 3));
    expect(t.stays.single.end, now);
  });

  test('ongoing still stay is closed at clipTo when openEnd is later', () {
    final t = analyzer.analyze(
      [_p(DateTime.utc(2026, 11, 8, 19, 5), still: true)],
      clipFrom: DateTime.utc(2026, 11, 8),
      clipTo: DateTime.utc(2026, 11, 8, 23, 59, 59, 999),
      openEnd: DateTime.utc(2026, 11, 9, 10),
    );
    expect(t.stays.single.end, DateTime.utc(2026, 11, 8, 23, 59, 59, 999));
  });

  test('without openEnd a trailing stillStart alone is not a stay', () {
    final t = analyzer.analyze([_p(_t0, still: true)]);
    expect(t.stays, isEmpty);
  });

  test('boundary neighbours outside the window are not drawn', () {
    final from = DateTime.utc(2026, 11, 8, 10);
    final to = DateTime.utc(2026, 11, 8, 11);
    final t = analyzer.analyze(
      [
        _p(DateTime.utc(2026, 11, 8, 9, 50)), // 창 앞 이웃
        _p(DateTime.utc(2026, 11, 8, 10, 5), lat: 37.5663 + 0.002),
        _p(DateTime.utc(2026, 11, 8, 10, 10), lat: 37.5663 + 0.004),
        _p(DateTime.utc(2026, 11, 8, 11, 10), lat: 37.5663 + 0.006), // 창 뒤 이웃
      ],
      clipFrom: from,
      clipTo: to,
    );
    final drawn = [for (final s in t.segments) ...s.points];
    expect(drawn.map((p) => p.recordedAt.minute), [5, 10]);
  });

  test('heartbeat still point keeps one continuous stay', () {
    final t = analyzer.analyze([
      _p(DateTime.utc(2026, 11, 8, 9, 3), still: true),
      _p(DateTime.utc(2026, 11, 8, 15, 3), lat: 37.5664, still: true),
      _p(DateTime.utc(2026, 11, 8, 18), lat: 37.5663 + 0.018),
    ]);
    expect(t.stays.single.start, DateTime.utc(2026, 11, 8, 9, 3));
    expect(t.stays.single.end, DateTime.utc(2026, 11, 8, 17, 59, 59, 999));
  });

  test('switching to dense after stillStart keeps the stay', () {
    final t = analyzer.analyze([
      _p(DateTime.utc(2026, 11, 8, 23), still: true),
      _p(DateTime.utc(2026, 11, 9, 8), lat: 37.5664, mode: RecordMode.dense),
    ]);
    expect(t.stays.single.start, DateTime.utc(2026, 11, 8, 23));
    expect(t.stays.single.end, DateTime.utc(2026, 11, 9, 7, 59, 59, 999));
    expect(t.segments.map((s) => s.mode), [
      RecordMode.normal,
      RecordMode.dense,
    ]);
  });

  // ── 2차 리뷰 ──

  test('same-spot gap over 12 hours without stillStart splits', () {
    final points = [
      _p(DateTime.utc(2026, 11, 6, 19)), // 금 19:00 기록 끔
      _p(DateTime.utc(2026, 11, 9, 8), lat: 37.5664), // 월 08:00 다시 켬
    ];
    expect(analyzer.analyze(points).stays, isEmpty);
    final saturday = analyzer.analyze(
      points,
      clipFrom: DateTime.utc(2026, 11, 7),
      clipTo: DateTime.utc(2026, 11, 7, 23, 59, 59, 999),
    );
    expect(saturday.stays, isEmpty);
  });

  test('same-spot gap of exactly 12 hours still joins', () {
    final t = analyzer.analyze([
      _p(DateTime.utc(2026, 11, 8, 8)),
      _p(DateTime.utc(2026, 11, 8, 20), lat: 37.5664),
    ]);
    expect(t.stays.single.end, DateTime.utc(2026, 11, 8, 20));
  });

  test('stillStart same-spot join has no upper bound', () {
    final t = analyzer.analyze([
      _p(DateTime.utc(2026, 11, 6, 19), still: true),
      _p(DateTime.utc(2026, 11, 9, 8), lat: 37.5664),
    ]);
    expect(t.stays.single.start, DateTime.utc(2026, 11, 6, 19));
    expect(t.stays.single.end, DateTime.utc(2026, 11, 9, 8));
  });

  test('ongoing stay without stillStart extends to openEnd', () {
    final t = analyzer.analyze(
      [_p(DateTime.utc(2026, 11, 8, 8, 58))],
      clipFrom: DateTime.utc(2026, 11, 8),
      clipTo: DateTime.utc(2026, 11, 8, 23, 59, 59, 999),
      openEnd: DateTime.utc(2026, 11, 8, 15),
    );
    expect(t.stays.single.start, DateTime.utc(2026, 11, 8, 8, 58));
    expect(t.stays.single.end, DateTime.utc(2026, 11, 8, 15));
  });

  test('ongoing stay without stillStart is not extended past 12 hours', () {
    final t = analyzer.analyze(
      [_p(DateTime.utc(2026, 11, 8, 8, 58))],
      clipFrom: DateTime.utc(2026, 11, 8),
      clipTo: DateTime.utc(2026, 11, 8, 23, 59, 59, 999),
      openEnd: DateTime.utc(2026, 11, 8, 21),
    );
    expect(t.stays, isEmpty);
  });

  test('non-still last point outside the window is not extended', () {
    final t = analyzer.analyze(
      [_p(DateTime.utc(2026, 11, 7, 20))], // 어제 20:00 — 창 앞 이웃
      clipFrom: DateTime.utc(2026, 11, 8),
      clipTo: DateTime.utc(2026, 11, 8, 23, 59, 59, 999),
      openEnd: DateTime.utc(2026, 11, 8, 7),
    );
    expect(t.stays, isEmpty);
  });

  test('mode change at the same spot without stillStart closes the stay', () {
    final t = analyzer.analyze([
      _p(DateTime.utc(2026, 11, 8, 8, 58)),
      _p(DateTime.utc(2026, 11, 8, 12), lat: 37.5664, mode: RecordMode.dense),
    ]);
    expect(t.stays.single.start, DateTime.utc(2026, 11, 8, 8, 58));
    expect(t.stays.single.end, DateTime.utc(2026, 11, 8, 11, 59, 59, 999));
    expect(t.segments.map((s) => s.mode), [
      RecordMode.normal,
      RecordMode.dense,
    ]);
  });

  test('stillStart after-neighbour extends to openEnd and is clipped', () {
    // 어제 보기: 창 안 P 23:55, 창 뒤 이웃 S 00:10(정지 감지). 그 뒤 점은 pointsAround 에 없다.
    final t = analyzer.analyze(
      [
        _p(DateTime.utc(2026, 11, 8, 23, 55)),
        _p(DateTime.utc(2026, 11, 9, 0, 10), lat: 37.5664, still: true),
      ],
      clipFrom: DateTime.utc(2026, 11, 8),
      clipTo: DateTime.utc(2026, 11, 8, 23, 59, 59, 999),
      openEnd: DateTime.utc(2026, 11, 9, 15),
    );
    expect(t.stays.single.start, DateTime.utc(2026, 11, 8, 23, 55));
    expect(t.stays.single.end, DateTime.utc(2026, 11, 8, 23, 59, 59, 999));
  });

  test('heartbeats are measured against the still anchor, not prev', () {
    // 정지 점에서 동쪽 약 88m · 서쪽 약 88m — 둘 사이는 약 176m.
    final t = analyzer.analyze([
      _p(DateTime.utc(2026, 11, 8, 9), still: true),
      _p(DateTime.utc(2026, 11, 8, 12), lng: 126.9779 + 0.001, still: true),
      _p(DateTime.utc(2026, 11, 8, 15), lng: 126.9779 - 0.001, still: true),
      _p(DateTime.utc(2026, 11, 8, 18), lat: 37.5663 + 0.018),
    ]);
    expect(t.stays.single.start, DateTime.utc(2026, 11, 8, 9));
    expect(t.stays.single.end, DateTime.utc(2026, 11, 8, 17, 59, 59, 999));
  });

  // ── 3차 리뷰 ──

  test('still heartbeat beyond 100m (native vouched) keeps one stay', () {
    // 네이티브가 정확도 80m 여유로 같은 자리라 본 150m 심장박동.
    final t = analyzer.analyze([
      _p(DateTime.utc(2026, 11, 8, 9, 3), still: true),
      _p(DateTime.utc(2026, 11, 8, 15, 3), lat: 37.5663 + 0.00135, still: true),
      _p(DateTime.utc(2026, 11, 8, 18), lat: 37.5663 + 0.018),
    ]);
    expect(t.stays.single.start, DateTime.utc(2026, 11, 8, 9, 3));
    expect(t.stays.single.end, DateTime.utc(2026, 11, 8, 17, 59, 59, 999));
  });

  test('arrival point before the still chain keeps the whole dwell', () {
    final t = analyzer.analyze([
      _p(DateTime.utc(2026, 11, 8, 8, 50), lng: 126.9779 - 0.00068), // 서 60m
      _p(DateTime.utc(2026, 11, 8, 9, 3), still: true),
      _p(DateTime.utc(2026, 11, 8, 12), lng: 126.9779 + 0.001, still: true),
      _p(DateTime.utc(2026, 11, 8, 18), lat: 37.5663 + 0.018),
    ]);
    expect(t.stays.single.start, DateTime.utc(2026, 11, 8, 8, 50));
    expect(t.stays.single.end, DateTime.utc(2026, 11, 8, 17, 59, 59, 999));
  });

  test('before-neighbour heartbeat and in-window heartbeat are one stay', () {
    final t = analyzer.analyze(
      [
        _p(DateTime.utc(2026, 11, 7, 22), lng: 126.9779 + 0.001, still: true),
        _p(DateTime.utc(2026, 11, 8, 4), lng: 126.9779 - 0.001, still: true),
        _p(DateTime.utc(2026, 11, 8, 9), lat: 37.5663 + 0.018),
      ],
      clipFrom: DateTime.utc(2026, 11, 8),
      clipTo: DateTime.utc(2026, 11, 8, 23, 59, 59, 999),
    );
    expect(t.stays.single.start, DateTime.utc(2026, 11, 8));
    expect(t.stays.single.end, DateTime.utc(2026, 11, 8, 8, 59, 59, 999));
  });

  test(
    'run broken right after a stillStart ends just before the next point',
    () {
      // 도착 A(서 60m) → 정지 S → 정지 점 동 90m 의 일반 점 N(A 와는 150m) 이 같은 구간.
      final t = analyzer.analyze([
        _p(DateTime.utc(2026, 11, 8, 8, 50), lng: 126.9779 - 0.00068),
        _p(DateTime.utc(2026, 11, 8, 9, 3), still: true),
        _p(DateTime.utc(2026, 11, 8, 12), lng: 126.9779 + 0.001),
      ]);
      expect(t.stays.first.start, DateTime.utc(2026, 11, 8, 8, 50));
      expect(t.stays.first.end, DateTime.utc(2026, 11, 8, 11, 59, 59, 999));
    },
  );

  // ── 4차 리뷰 ──

  test('still points over 1 km apart do not merge into a midpoint stay', () {
    // 정지 08:00(0m) → 정지 09:30(5km 북) → 멀리 12:00. 사이 점이 없어도 두 머문 곳.
    final t = analyzer.analyze([
      _p(DateTime.utc(2026, 11, 8, 8), still: true),
      _p(DateTime.utc(2026, 11, 8, 9, 30), lat: 37.5663 + 0.045, still: true),
      _p(DateTime.utc(2026, 11, 8, 12), lng: 126.9779 + 0.1),
    ]);
    expect(t.stays.length, 2);
    expect(t.stays[0].start, DateTime.utc(2026, 11, 8, 8));
    expect(t.stays[0].end, DateTime.utc(2026, 11, 8, 9, 29, 59, 999));
    expect(t.stays[0].lat, closeTo(37.5663, 1e-9));
    expect(t.stays[1].start, DateTime.utc(2026, 11, 8, 9, 30));
    expect(t.stays[1].end, DateTime.utc(2026, 11, 8, 11, 59, 59, 999));
    expect(t.stays[1].lat, closeTo(37.5663 + 0.045, 1e-9));
  });
}
