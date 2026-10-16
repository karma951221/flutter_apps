import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/domain/export/policy/gpx_encoder.dart';
import 'package:pawlog/domain/walk/entity/geo_point.dart';
import 'package:pawlog/domain/walk/entity/walk_track_point.dart';

WalkTrackPoint _p(double lat, double lng, DateTime at) =>
    WalkTrackPoint(point: GeoPoint(lat: lat, lng: lng), recordedAt: at);

void main() {
  final startedAt = DateTime.utc(2026, 10, 17, 0, 12);

  test('점 2개와 메모가 있는 문서 전체', () {
    final xml = GpxEncoder.encode(
      name: '콩이, 보리',
      description: '공원 한 바퀴',
      startedAt: startedAt,
      points: [
        _p(37.5665, 126.978, DateTime.utc(2026, 10, 17, 0, 12, 3)),
        _p(37.5666, 126.9781, DateTime.utc(2026, 10, 17, 0, 12, 8, 500)),
      ],
    );
    expect(xml, '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="pawlog" xmlns="http://www.topografix.com/GPX/1/1">
  <metadata><name>콩이, 보리</name><time>2026-10-17T00:12:00Z</time></metadata>
  <trk>
    <name>콩이, 보리</name>
    <desc>공원 한 바퀴</desc>
    <type>walking</type>
    <trkseg>
      <trkpt lat="37.566500" lon="126.978000"><time>2026-10-17T00:12:03Z</time></trkpt>
      <trkpt lat="37.566600" lon="126.978100"><time>2026-10-17T00:12:08Z</time></trkpt>
    </trkseg>
  </trk>
</gpx>
''');
  });

  test('이름과 메모의 & < > " \' 를 이스케이프한다', () {
    final xml = GpxEncoder.encode(
      name: '콩이 & "보리" <3',
      description: "it's >",
      startedAt: startedAt,
      points: const [],
    );
    expect(xml, contains('<name>콩이 &amp; &quot;보리&quot; &lt;3</name>'));
    expect(xml, contains('<desc>it&apos;s &gt;</desc>'));
  });

  test('메모가 null 이거나 공백이면 desc 를 쓰지 않는다', () {
    for (final d in [null, '', '   ']) {
      final xml = GpxEncoder.encode(
        name: 'a',
        description: d,
        startedAt: startedAt,
        points: const [],
      );
      expect(xml, isNot(contains('<desc>')));
    }
  });

  test('점이 없으면 trkseg 가 비어 있다', () {
    final xml = GpxEncoder.encode(
      name: 'a',
      startedAt: startedAt,
      points: const [],
    );
    expect(xml, contains('    <trkseg>\n    </trkseg>\n'));
  });

  test('현지 시각도 UTC Z 로 바뀐다', () {
    final xml = GpxEncoder.encode(
      name: 'a',
      startedAt: startedAt.toLocal(),
      points: [_p(1, 2, DateTime.utc(2026, 10, 17, 1, 2, 3).toLocal())],
    );
    expect(xml, contains('<time>2026-10-17T00:12:00Z</time>'));
    expect(xml, contains('<time>2026-10-17T01:02:03Z</time></trkpt>'));
  });

  test('좌표는 소수 6자리로 반올림한다', () {
    final xml = GpxEncoder.encode(
      name: 'a',
      startedAt: startedAt,
      points: [_p(37.1234567, 126.1, DateTime.utc(2026, 10, 17))],
    );
    expect(xml, contains('lat="37.123457" lon="126.100000"'));
  });

  test('fileName 은 현지 시작 시각을 쓴다', () {
    expect(
      GpxEncoder.fileName(DateTime(2026, 10, 17, 9, 5)),
      'pawlog-2026-10-17-0905.gpx',
    );
  });
}
