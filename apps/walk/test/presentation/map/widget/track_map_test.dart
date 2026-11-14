import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:walk/domain/location/entity/day_track.dart';
import 'package:walk/domain/location/entity/location_point.dart';
import 'package:walk/domain/location/entity/map_style.dart';
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
    MapStyle style = MapStyle.simple,
    ThemeData? theme,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light(),
        home: Scaffold(
          body: TrackMap(
            track: track,
            // 지도 탭은 빌드마다 새 목록을 넘긴다.
            spots: [const LatLng(37.5, 127.0)],
            entries: const [],
            fitKey: 'day',
            bottomInset: inset,
            style: style,
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

  group('같은 기간에 점이 늘면', () {
    MapCamera camera(WidgetTester tester) =>
        MapCamera.of(tester.element(find.byType(PolylineLayer)));

    bool onScreen(WidgetTester tester, LatLng p) {
      final o = camera(tester).latLngToScreenOffset(p);
      final size = camera(tester).nonRotatedSize;
      return o.dx >= 0 &&
          o.dy >= 0 &&
          o.dx <= size.width &&
          o.dy <= size.height;
    }

    testWidgets('새 점이 화면 밖이면 카메라를 다시 맞춘다', (tester) async {
      await pump(tester, _track(37.5));
      const far = LatLng(37.9, 127.0);
      expect(onScreen(tester, far), isFalse);

      await pump(tester, _track(37.9));
      await tester.pumpAndSettle();

      expect(onScreen(tester, far), isTrue);
    });

    testWidgets('새 점이 화면 안이면 카메라를 그대로 둔다', (tester) async {
      await pump(tester, _track(37.5));
      await tester.pumpAndSettle();
      final before = camera(tester).center;

      // 새로고침으로 같은 점의 새 이동선이 온다 — 모두 화면 안.
      await pump(tester, _track(37.5));
      await tester.pumpAndSettle();

      expect(camera(tester).center, before);
    });

    testWidgets('직접 지도를 옮긴 뒤에는 따라가지 않는다', (tester) async {
      await pump(tester, _track(37.5));
      await tester.drag(find.byType(FlutterMap), const Offset(0, 200));
      await tester.pumpAndSettle();
      final moved = camera(tester).center;

      await pump(tester, _track(37.9));
      await tester.pumpAndSettle();

      expect(camera(tester).center, moved);
    });
  });

  group('위성에서는 동선을 밝게', () {
    Polyline line(WidgetTester tester) => tester
        .widget<PolylineLayer>(find.byType(PolylineLayer))
        .polylines
        .single;

    for (final (name, theme) in [
      ('밝은 테마', AppTheme.light()),
      ('어두운 테마', AppTheme.dark()),
    ]) {
      testWidgets('$name: 다른 종류보다 밝고 어두운 테두리', (tester) async {
        await pump(tester, _track(37.5), theme: theme);
        final plain = line(tester);
        expect(plain.borderStrokeWidth, 0);

        await pump(
          tester,
          _track(37.5),
          style: MapStyle.satellite,
          theme: theme,
        );
        final sat = line(tester);

        expect(
          sat.color.computeLuminance(),
          // 어두운 테마는 primary 가 이미 밝은 쪽이라 같을 수 있다.
          greaterThanOrEqualTo(
            plain.color.withValues(alpha: 1).computeLuminance(),
          ),
        );
        expect(sat.color.a, greaterThan(plain.color.a));
        expect(sat.borderStrokeWidth, greaterThan(0));
      });
    }
  });
}
