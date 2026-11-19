import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/domain/location/entity/day_track.dart';
import 'package:walk/presentation/diary/widget/entry_media_view.dart';
import 'package:walk/presentation/map/widget/entry_pin.dart';
import 'package:walk/presentation/map/widget/track_map.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/stub_tile_provider.dart';

class _MockStore extends Mock implements MediaStore {}

DiaryEntry _entry(
  String id, {
  double lat = 37.5,
  bool photo = true,
  int hour = 12,
}) => DiaryEntry(
  id: id,
  storyId: 's',
  body: '본문 $id',
  occurredAt: DateTime(2026, 10, 10, hour),
  createdAt: DateTime(2026, 10, 10, hour),
  updatedAt: DateTime(2026, 10, 10, hour),
  location: EntryLocation(lat: lat, lng: 127.0),
  media: [if (photo) photoMedia('m-$id')],
  tags: const [],
);

void main() {
  setUp(() {
    final store = _MockStore();
    when(
      () => store.resolve(any()),
    ).thenAnswer((inv) => File('/fake/${inv.positionalArguments.single}'));
    getIt
      ..registerFactory<TileProvider>(StubTileProvider.new)
      ..registerSingleton<MediaStore>(store);
  });
  tearDown(() => getIt.reset());

  final opened = <String>[];
  setUp(opened.clear);

  Future<void> pump(WidgetTester tester, List<DiaryEntry> entries) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TrackMap(
            track: const DayTrack(segments: [], stays: []),
            spots: const [],
            entries: entries,
            fitKey: 'day',
            onOpenEntry: (e) => opened.add(e.id),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder preview(String id) => find.byKey(ValueKey('map-pin-preview-$id'));

  testWidgets('핀은 사진 없이 점 · 숫자만, 누르면 정사각 미리보기', (tester) async {
    // 멀리 떨어진 a 하나와, 같은 자리 b · c 묶음.
    await pump(tester, [
      _entry('a', lat: 37.6),
      _entry('b', hour: 9),
      _entry('c', photo: false, hour: 10),
    ]);

    expect(find.byType(EntryMediaView), findsNothing);
    expect(find.byKey(const ValueKey('map-pin-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-pin-b')), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.byType(EntryPinPreview), findsNothing);

    await tester.tap(find.byKey(const ValueKey('map-pin-b')));
    await tester.pump();
    expect(preview('b'), findsOneWidget);
    expect(preview('c'), findsOneWidget);
    expect(preview('a'), findsNothing);
    expect(
      tester.getSize(preview('b')),
      const Size.square(EntryPinLayer.previewSize),
    );
    // 사진 칸은 사진, 글 칸은 글.
    expect(find.byType(EntryMediaView), findsOneWidget);
    expect(find.text('본문 c'), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets('미리보기 칸을 누르면 그 기록을 연다', (tester) async {
    await pump(tester, [_entry('b', hour: 9), _entry('c', hour: 10)]);

    await tester.tap(find.byKey(const ValueKey('map-pin-b')));
    await tester.pump();
    await tester.tap(preview('c'));
    await tester.pump();

    expect(opened, ['c']);
  });

  testWidgets('지도 빈 곳이나 같은 핀을 다시 누르면 닫히고, 다른 핀은 바꾼다', (tester) async {
    await pump(tester, [_entry('a', lat: 37.6), _entry('b')]);

    await tester.tap(find.byKey(const ValueKey('map-pin-b')));
    await tester.pump();
    expect(preview('b'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-pin-b')));
    await tester.pump();
    expect(find.byType(EntryPinPreview), findsNothing);

    await tester.tap(find.byKey(const ValueKey('map-pin-b')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('map-pin-a')));
    await tester.pump();
    expect(preview('a'), findsOneWidget);
    expect(preview('b'), findsNothing);

    // 핀 · 미리보기에서 먼 곳.
    await tester.tapAt(const Offset(20, 1380));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(EntryPinPreview), findsNothing);
    expect(opened, isEmpty);
  });
}
