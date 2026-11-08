import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:walk/domain/location/entity/day_track.dart';
import 'package:walk/domain/location/entity/location_point.dart';
import 'package:walk/domain/location/entity/record_mode.dart';
import 'package:walk/domain/location/entity/track_segment.dart';
import 'package:walk/presentation/map/widget/track_map.dart';

import '../../../support/stub_tile_provider.dart';

DayTrack _track(double lat) => DayTrack(
  segments: [
    TrackSegment(
      points: [
        for (var i = 0; i < 3; i++)
          LocationPoint(
            recordedAt: DateTime.utc(2026, 11, 8, 9, i),
            lat: lat + i * 0.001,
            lng: 127.0,
            mode: RecordMode.normal,
          ),
      ],
      mode: RecordMode.normal,
    ),
  ],
  stays: const [],
);

void main() {
  setUp(() => getIt.registerFactory<TileProvider>(StubTileProvider.new));
  tearDown(() => getIt.reset());

  Future<void> pump(
    WidgetTester tester,
    DayTrack track, {
    double inset = 0,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: TrackMap(
            track: track,
            // 지도 탭은 빌드마다 새 목록을 넘긴다.
            spots: [const LatLng(37.5, 127.0)],
            entries: const [],
            fitKey: 'day',
            bottomInset: inset,
            onOpenEntry: (_) {},
          ),
        ),
      ),
    );
  }

  List<LatLng> drawnPoints(WidgetTester tester) => tester
      .widget<PolylineLayer>(find.byType(PolylineLayer))
      .polylines
      .single
      .points;

  testWidgets('같은 이동선으로 다시 그리면 선 좌표를 새로 만들지 않는다', (tester) async {
    final track = _track(37.5);
    await pump(tester, track);
    final first = drawnPoints(tester);

    // 시트 높이가 바뀌는 등 다른 이유로 다시 그린다.
    await pump(tester, track, inset: 100);

    expect(identical(drawnPoints(tester), first), isTrue);
  });

  testWidgets('이동선이 바뀌면 선 좌표를 다시 만든다', (tester) async {
    await pump(tester, _track(37.5));
    final first = drawnPoints(tester);

    await pump(tester, _track(37.6));

    expect(identical(drawnPoints(tester), first), isFalse);
    expect(drawnPoints(tester).first, const LatLng(37.6, 127.0));
  });
}
