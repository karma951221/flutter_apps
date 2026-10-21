import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/diary_view_mode.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/presentation/diary/widget/diary_entries_view.dart';
import 'package:walk/presentation/diary/widget/entry_media_view.dart';
import 'package:walk/presentation/diary/widget/entry_meta.dart';
import 'package:walk/presentation/diary/widget/feed_view.dart';
import 'package:walk/presentation/diary/widget/prose_view.dart';
import 'package:walk/presentation/diary/widget/reels_view.dart';

import '../../../support/diary_fixtures.dart';

class _MockStore extends Mock implements MediaStore {}

/// 영상 자리의 가짜. 만들어진 · 버려진 파일 경로를 남긴다.
class _FakeSurface extends StatefulWidget {
  const _FakeSurface(this.path, this.log);

  final String path;
  final List<String> log;

  @override
  State<_FakeSurface> createState() => _FakeSurfaceState();
}

class _FakeSurfaceState extends State<_FakeSurface> {
  @override
  void initState() {
    super.initState();
    widget.log.add('play ${widget.path}');
  }

  @override
  void dispose() {
    widget.log.add('dispose ${widget.path}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text('video ${widget.path}');
}

DiaryEntry _entry(
  String id, {
  String? body,
  String storyId = Story.dailyId,
  DateTime? at,
  List<EntryMedia> media = const [],
  List<String> tags = const [],
  EntryLocation? location,
}) => DiaryEntry(
  id: id,
  storyId: storyId,
  body: body ?? '본문 $id',
  occurredAt: at ?? diaryT0.subtract(const Duration(hours: 1)),
  createdAt: diaryT0,
  updatedAt: diaryT0,
  location: location,
  media: media,
  tags: tags,
);

void main() {
  late List<String> videoLog;
  late List<DiaryEntry> opened;

  setUpAll(() => registerFallbackValue(''));

  setUp(() {
    videoLog = [];
    opened = [];
    final store = _MockStore();
    when(
      () => store.resolve(any()),
    ).thenAnswer((inv) => File('/fake/${inv.positionalArguments.single}'));
    getIt
      ..registerSingleton<MediaStore>(store)
      ..registerSingleton<Clock>(MutableClock(diaryT0));
  });

  tearDown(() => getIt.reset());

  Future<void> pump(
    WidgetTester tester,
    DiaryViewMode mode,
    List<DiaryEntry> entries, {
    bool showStoryName = false,
    bool active = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DiaryEntriesView(
            mode: mode,
            entries: entries,
            showStoryName: showStoryName,
            active: active,
            storyTitles: const {Story.dailyId: '일상', 'jeju': '제주 여행'},
            onOpen: opened.add,
            videoBuilder: (context, file) => _FakeSurface(file.path, videoLog),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder mediaOf(String id) =>
      find.byWidgetPredicate((w) => w is EntryMediaView && w.media.id == id);

  final mixed = [
    _entry('a', body: '바다', media: [photoMedia('p1'), photoMedia('p2')]),
    _entry('b', body: '출근', at: diaryT0.subtract(const Duration(days: 1))),
  ];

  group('같은 기록으로 세 모드', () {
    testWidgets('줄글: 날짜 머리로 묶고 글과 썸네일 줄', (tester) async {
      await pump(tester, DiaryViewMode.prose, mixed);

      expect(find.byType(ProseView), findsOneWidget);
      expect(find.text('오늘'), findsOneWidget);
      expect(find.text('어제'), findsOneWidget);
      expect(find.text('바다'), findsOneWidget);
      expect(find.text('출근'), findsOneWidget);
      expect(mediaOf('p1'), findsOneWidget);
      expect(mediaOf('p2'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('오늘')).dy,
        lessThan(tester.getTopLeft(find.text('바다')).dy),
      );
      expect(
        tester.getTopLeft(find.text('바다')).dy,
        lessThan(tester.getTopLeft(find.text('어제')).dy),
      );
    });

    testWidgets('줄글: 같은 날 기록은 날짜 머리 하나', (tester) async {
      await pump(tester, DiaryViewMode.prose, [
        _entry('a'),
        _entry('b', at: diaryT0.subtract(const Duration(hours: 2))),
      ]);

      expect(find.text('오늘'), findsOneWidget);
      expect(find.text('본문 a'), findsOneWidget);
      expect(find.text('본문 b'), findsOneWidget);
    });

    testWidgets('피드: 기록마다 카드, 미디어는 첫 장부터', (tester) async {
      await pump(tester, DiaryViewMode.feed, mixed);

      expect(find.byType(FeedView), findsOneWidget);
      expect(mediaOf('p1'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.widgetWithText(Card, '바다'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('출근'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.widgetWithText(Card, '출근'), findsOneWidget);
    });

    testWidgets('릴스: 한 화면에 기록 하나', (tester) async {
      await pump(tester, DiaryViewMode.reels, mixed);

      expect(find.byType(ReelsView), findsOneWidget);
      expect(find.text('바다'), findsOneWidget);
      expect(find.text('출근'), findsNothing);
    });
  });

  testWidgets('피드: 좌우로 넘기면 두 번째 미디어', (tester) async {
    await pump(tester, DiaryViewMode.feed, mixed);

    await tester.drag(mediaOf('p1'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(mediaOf('p2'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
  });

  testWidgets('릴스: 시각 · 스토리 줄과 글 뒤 전체에 진한 그늘(scrim ≥ 0.6)이 깔린다', (
    tester,
  ) async {
    await pump(tester, DiaryViewMode.reels, mixed, showStoryName: true);

    final meta = find.byType(EntryMeta);
    final behind = find
        .ancestor(of: meta, matching: find.byType(DecoratedBox))
        .first;
    final decoration =
        tester.widget<DecoratedBox>(behind).decoration as BoxDecoration;
    final colors = [?decoration.color, ...?decoration.gradient?.colors];
    final scrim = Theme.of(tester.element(meta)).colorScheme.scrim;

    expect(colors, isNotEmpty);
    for (final c in colors) {
      expect(c.withValues(alpha: 1), scrim.withValues(alpha: 1));
      // 위가 투명하게 바래는 그라데이션이면 첫 줄(시각 · 스토리)이 밝은 사진 위에 뜬다.
      expect(c.a, greaterThanOrEqualTo(0.6), reason: '$colors');
    }
    final box = tester.getRect(behind);
    for (final text in [meta, find.text('바다')]) {
      final r = tester.getRect(text);
      expect(box.contains(r.topLeft) && box.contains(r.bottomRight), isTrue);
    }
  });

  testWidgets('릴스: 세로로 다음 기록, 가로로 같은 기록의 다음 미디어', (tester) async {
    await pump(tester, DiaryViewMode.reels, mixed);

    await tester.drag(mediaOf('p1'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(mediaOf('p2'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('바다'), findsOneWidget);

    await tester.drag(mediaOf('p2'), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('바다'), findsNothing);
    expect(find.text('출근'), findsOneWidget);
  });

  testWidgets('릴스: 보이는 영상만 재생하고 넘긴 영상은 버린다', (tester) async {
    await pump(tester, DiaryViewMode.reels, [
      _entry('a', media: [videoMedia('v1'), videoMedia('v2')]),
      _entry('b', media: [videoMedia('v3')]),
    ]);
    expect(videoLog, ['play /fake/media/v1.mp4']);

    await tester.drag(
      find.text('video /fake/media/v1.mp4'),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(
      videoLog.skip(1),
      unorderedEquals([
        'dispose /fake/media/v1.mp4',
        'play /fake/media/v2.mp4',
      ]),
    );

    videoLog.clear();
    await tester.drag(
      find.text('video /fake/media/v2.mp4'),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(
      videoLog,
      unorderedEquals([
        'dispose /fake/media/v2.mp4',
        'play /fake/media/v3.mp4',
      ]),
    );
  });

  testWidgets('릴스: 반쯤 걸친 다음 기록 · 다음 장의 영상은 재생하지 않는다', (tester) async {
    await pump(tester, DiaryViewMode.reels, [
      _entry('a', media: [videoMedia('v1'), videoMedia('v2')]),
      _entry('b', media: [videoMedia('v3')]),
    ]);

    final down = await tester.startGesture(
      tester.getCenter(find.text('video /fake/media/v1.mp4')),
    );
    await down.moveBy(const Offset(0, -20));
    await down.moveBy(const Offset(0, -180));
    await tester.pump();
    expect(find.text('본문 b'), findsOneWidget); // 다음 기록이 걸쳐 보인다
    expect(videoLog, ['play /fake/media/v1.mp4']);
    await down.moveBy(const Offset(0, 200));
    await down.up();
    await tester.pumpAndSettle();

    final side = await tester.startGesture(
      tester.getCenter(find.text('video /fake/media/v1.mp4')),
    );
    await side.moveBy(const Offset(-20, 0));
    await side.moveBy(const Offset(-200, 0));
    await tester.pump();
    expect(videoLog, ['play /fake/media/v1.mp4']);
    await side.up();
    await tester.pumpAndSettle();
  });

  testWidgets('릴스: 탭이 가려지면(active false) 영상을 멈추고 버린다', (tester) async {
    final entries = [
      _entry('a', media: [videoMedia('v1')]),
    ];
    await pump(tester, DiaryViewMode.reels, entries);
    expect(videoLog, ['play /fake/media/v1.mp4']);

    await pump(tester, DiaryViewMode.reels, entries, active: false);
    expect(videoLog, ['play /fake/media/v1.mp4', 'dispose /fake/media/v1.mp4']);
    expect(mediaOf('v1'), findsOneWidget); // 썸네일로 남는다

    await pump(tester, DiaryViewMode.reels, entries);
    expect(videoLog.last, 'play /fake/media/v1.mp4');
  });

  testWidgets('피드 · 줄글의 영상은 재생하지 않고 썸네일', (tester) async {
    final entries = [
      _entry('a', media: [videoMedia('v1')]),
    ];
    await pump(tester, DiaryViewMode.feed, entries);
    expect(mediaOf('v1'), findsOneWidget);
    expect(videoLog, isEmpty);

    await pump(tester, DiaryViewMode.prose, entries);
    expect(mediaOf('v1'), findsOneWidget);
    expect(videoLog, isEmpty);
  });

  group('스토리 이름 · 위치 · 태그', () {
    final trip = [
      _entry(
        'a',
        body: '바다',
        storyId: 'jeju',
        location: const EntryLocation(placeName: '애월읍', lat: 33.4, lng: 126.3),
        tags: ['제주', '바다'],
      ),
    ];

    // 피드 카드 머리는 feed_view_test 에서 본다.
    for (final mode in [DiaryViewMode.prose, DiaryViewMode.reels]) {
      testWidgets('${mode.name}: 전체에서만 스토리 이름', (tester) async {
        await pump(tester, mode, trip, showStoryName: true);
        expect(find.textContaining('제주 여행'), findsOneWidget);

        await pump(tester, mode, trip);
        expect(find.textContaining('제주 여행'), findsNothing);
      });

      testWidgets('${mode.name}: 위치 · 태그 칩', (tester) async {
        await pump(tester, mode, trip);

        expect(find.text('📍 애월읍'), findsOneWidget);
        expect(find.widgetWithText(Chip, '#제주'), findsOneWidget);
        expect(find.widgetWithText(Chip, '#바다'), findsOneWidget);
      });
    }

    for (final mode in DiaryViewMode.values) {
      testWidgets('${mode.name}: 미디어 없는 기록', (tester) async {
        await pump(tester, mode, [_entry('a', body: '글만')]);

        expect(find.text('글만'), findsOneWidget);
        expect(find.byType(EntryMediaView), findsNothing);
        expect(find.textContaining('📍'), findsNothing);
      });
    }
  });

  testWidgets('줄글: 1만 자 본문을 자르지 않는다', (tester) async {
    final long = List.filled(10000, '가').join();
    await pump(tester, DiaryViewMode.prose, [_entry('a', body: long)]);

    expect(tester.widget<Text>(find.text(long)).maxLines, isNull);
  });

  for (final mode in DiaryViewMode.values) {
    testWidgets('${mode.name}: 기록을 누르면 onOpen', (tester) async {
      await pump(tester, mode, mixed);

      if (mode == DiaryViewMode.feed) {
        // 본문이 미디어 아래, 첫 화면 밖에 있다.
        await tester.ensureVisible(find.text('바다'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('바다'));
      await tester.pump();

      expect([for (final e in opened) e.id], ['a']);
    });
  }
}
