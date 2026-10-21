import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/presentation/diary/widget/entry_media_view.dart';
import 'package:walk/presentation/diary/widget/feed_view.dart';
import 'package:walk/presentation/diary/widget/story_avatar.dart';

import '../../../support/diary_fixtures.dart';

class _MockStore extends Mock implements MediaStore {}

final _jeju = Story(
  id: 'jeju',
  title: '제주 여행',
  status: StoryStatus.open,
  startedAt: diaryT0,
  createdAt: diaryT0,
);

DiaryEntry _entry(
  String id, {
  String? body,
  String storyId = 'jeju',
  DateTime? at,
  List<EntryMedia> media = const [],
  List<String> tags = const [],
  EntryLocation? location,
}) => DiaryEntry(
  id: id,
  storyId: storyId,
  body: body ?? '본문 $id',
  occurredAt: at ?? diaryT0.subtract(const Duration(hours: 2)),
  createdAt: diaryT0,
  updatedAt: diaryT0,
  location: location,
  media: media,
  tags: tags,
);

void main() {
  late List<String> log;

  setUpAll(() => registerFallbackValue(''));

  setUp(() {
    log = [];
    final store = _MockStore();
    when(
      () => store.resolve(any()),
    ).thenAnswer((inv) => File('/fake/${inv.positionalArguments.single}'));
    getIt.registerSingleton<MediaStore>(store);
  });

  tearDown(() => getIt.reset());

  Future<void> pump(
    WidgetTester tester,
    List<DiaryEntry> entries, {
    bool actions = true,
    Widget? header,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FeedView(
            entries: entries,
            now: diaryT0,
            stories: {'jeju': _jeju},
            covers: {'jeju': File('/fake/cover.jpg')},
            header: header,
            onOpen: (e) => log.add('open ${e.id}'),
            onOpenStory: (s) => log.add('story ${s.id}'),
            onTag: (t) => log.add('tag $t'),
            onAction: actions ? (e, a) => log.add('${a.name} ${e.id}') : null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final trip = _entry(
    'a',
    body: '노을',
    media: [photoMedia('p1'), photoMedia('p2'), photoMedia('p3')],
    location: const EntryLocation(placeName: '애월읍', lat: 33.4, lng: 126.3),
    tags: ['노을'],
  );

  testWidgets('머리: 표지 작은 원 · 스토리 이름 · 장소, 아래 상대 시각', (tester) async {
    await pump(tester, [trip]);

    final circle = tester.widget<StoryCoverCircle>(
      find.byType(StoryCoverCircle),
    );
    expect(circle.label, '제주 여행');
    expect(circle.image?.path, '/fake/cover.jpg');
    expect(circle.radius, lessThan(StoryCoverCircle.defaultRadius));
    expect(find.text('제주 여행'), findsOneWidget);
    expect(find.text('애월읍'), findsOneWidget);
    expect(find.text('2시간 전'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('제주 여행')).dy,
      lessThan(tester.getTopLeft(find.byType(MediaPager)).dy),
    );
  });

  testWidgets('미디어는 4:5 칸, 1/n 표시', (tester) async {
    await pump(tester, [trip]);

    final box = tester.getSize(find.byType(MediaPager));
    expect(box.width / box.height, closeTo(4 / 5, 0.01));
    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('영상은 자동재생하지 않고 썸네일 + ▶', (tester) async {
    await pump(tester, [
      _entry('v', media: [videoMedia('v1')]),
    ]);

    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
  });

  testWidgets('몸통 탭 → onOpen, 머리 탭 → onOpenStory, 태그 탭 → onTag', (
    tester,
  ) async {
    await pump(tester, [trip]);

    await tester.tap(find.byType(MediaPager));
    await tester.pump();
    await tester.tap(find.text('제주 여행'));
    await tester.pump();
    await tester.ensureVisible(find.text('#노을'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#노을'));
    await tester.pump();
    await tester.tap(find.text('노을'));
    await tester.pump();

    expect(log, ['open a', 'story jeju', 'tag 노을', 'open a']);
  });

  testWidgets('⋮ 수정 · 스토리 옮기기 · 휴지통', (tester) async {
    await pump(tester, [trip]);

    for (final (label, action) in [
      ('수정', 'edit'),
      ('스토리 옮기기', 'move'),
      ('휴지통으로', 'trash'),
    ]) {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(log.last, '$action a');
    }
  });

  testWidgets('onAction 이 없으면 ⋮ 를 두지 않는다', (tester) async {
    await pump(tester, [trip], actions: false);

    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('header 를 첫 칸으로 함께 스크롤한다', (tester) async {
    await pump(tester, [trip], header: const Text('동그라미 줄'));

    expect(
      tester.getTopLeft(find.text('동그라미 줄')).dy,
      lessThan(tester.getTopLeft(find.text('제주 여행')).dy),
    );
  });

  testWidgets('1만 자 본문은 3줄로 접고 더 보기로 펼친다', (tester) async {
    final long = List.filled(10000, '가').join();
    await pump(tester, [_entry('a', body: long)]);

    Text body() => tester.widget<Text>(find.text(long));
    expect(body().maxLines, 3);
    expect(find.text('더 보기'), findsOneWidget);

    await tester.tap(find.text('더 보기'));
    await tester.pumpAndSettle();

    expect(body().maxLines, isNull);
    expect(find.text('더 보기'), findsNothing);
  });

  testWidgets('짧은 본문엔 더 보기가 없다', (tester) async {
    await pump(tester, [_entry('a', body: '짧은 글')]);

    expect(find.text('더 보기'), findsNothing);
  });

  testWidgets('모르는 스토리면 이름 · 원 없이 장소만', (tester) async {
    await pump(tester, [
      _entry(
        'x',
        storyId: 'gone',
        location: const EntryLocation(placeName: '애월읍', lat: 33.4, lng: 126.3),
      ),
    ]);

    expect(find.byType(StoryCoverCircle), findsNothing);
    expect(find.text('애월읍'), findsOneWidget);
  });
}
