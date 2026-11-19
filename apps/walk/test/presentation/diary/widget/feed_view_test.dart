import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

import '../../../support/diary_fixtures.dart';

class _MockStore extends Mock implements MediaStore {}

final _jeju = Story(
  id: 'jeju',
  title: '제주 여행',
  status: StoryStatus.open,
  startedAt: diaryT0,
  createdAt: diaryT0,
);

final _daily = Story(
  id: Story.dailyId,
  title: '',
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
            stories: {'jeju': _jeju, Story.dailyId: _daily},
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

  testWidgets('머리: 날짜 · 시각 + 장소, 일상이 아닌 스토리 이름은 작게', (tester) async {
    await pump(tester, [trip]);

    expect(find.text('오늘 · 오전 7:00'), findsOneWidget);
    expect(find.text('애월읍'), findsOneWidget);
    expect(find.text('제주 여행'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('오늘 · 오전 7:00')).dy,
      lessThan(tester.getTopLeft(find.byType(MediaPager)).dy),
    );
    expect(
      tester.getTopLeft(find.text('제주 여행')).dy,
      lessThan(tester.getTopLeft(find.byType(MediaPager)).dy),
    );
    // 스토리 이름은 머리의 날짜 · 시각보다 작은 글씨.
    final dateSize = tester
        .renderObject<RenderParagraph>(find.text('오늘 · 오전 7:00'))
        .text
        .style!
        .fontSize!;
    final storySize = tester
        .renderObject<RenderParagraph>(find.text('제주 여행'))
        .text
        .style!
        .fontSize!;
    expect(storySize, lessThan(dateSize));
    // 스토리 표지 원은 두지 않는다.
    expect(find.byType(CircleAvatar), findsNothing);
  });

  testWidgets('일상 스토리면 스토리 이름을 두지 않는다', (tester) async {
    await pump(tester, [
      _entry(
        'd',
        storyId: Story.dailyId,
        at: diaryT0.subtract(const Duration(days: 1, hours: 3)),
        location: const EntryLocation(placeName: '회사', lat: 37.5, lng: 127),
      ),
    ]);

    expect(find.text('어제 · 오전 6:00'), findsOneWidget);
    expect(find.text('회사'), findsOneWidget);
    expect(find.text('일상'), findsNothing);
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

    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  testWidgets('사진 탭 → onOpen, 스토리 이름 탭 → onOpenStory, 태그 탭 → onTag', (
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

    expect(log, ['open a', 'story jeju', 'tag 노을']);
  });

  testWidgets('글 · 머리 날짜를 눌러도 onOpen 하지 않는다', (tester) async {
    await pump(tester, [trip]);

    await tester.tap(find.text('노을'));
    await tester.pump();
    await tester.tap(find.text('오늘 · 오전 7:00'));
    await tester.pump();

    expect(log, isEmpty);
  });

  testWidgets('긴 글은 눌러도 뷰어 대신 더 보기로만 펼친다', (tester) async {
    final long = List.filled(10000, '가').join();
    await pump(tester, [_entry('a', body: long)]);

    await tester.tap(find.text(long));
    await tester.pump();
    await tester.tap(find.text('더 보기'));
    await tester.pumpAndSettle();

    expect(log, isEmpty);
    expect(tester.widget<Text>(find.text(long)).maxLines, isNull);
  });

  testWidgets('카드에 ⋮ 는 없고, 길게 누르면 수정 · 스토리 옮기기 · 휴지통 시트', (tester) async {
    await pump(tester, [trip]);

    expect(find.byIcon(Icons.more_vert), findsNothing);
    for (final (label, action) in [
      ('수정', 'edit'),
      ('스토리 옮기기', 'move'),
      ('휴지통으로', 'trash'),
    ]) {
      await tester.longPress(find.byType(Card));
      await tester.pumpAndSettle();
      expect(find.byType(AppSheetScaffold), findsOneWidget);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(log.last, '$action a');
    }
  });

  testWidgets('휴지통 행은 error 색', (tester) async {
    await pump(tester, [trip]);

    await tester.longPress(find.byType(Card));
    await tester.pumpAndSettle();
    final trash = find.descendant(
      of: find.byKey(const Key('feed-action-trash')),
      matching: find.byType(Text),
    );
    final theme = Theme.of(tester.element(trash));
    expect(tester.widget<Text>(trash).style?.color, theme.colorScheme.error);
  });

  testWidgets('머리의 고치기 아이콘(툴팁 수정)은 바로 수정', (tester) async {
    await pump(tester, [trip]);

    expect(find.byTooltip('수정'), findsOneWidget);
    await tester.tap(find.byKey(const Key('feed-edit')));
    await tester.pumpAndSettle();
    expect(log.last, 'edit a');
  });

  testWidgets('onAction 이 없으면 고치기 아이콘 · 길게 누르기 시트를 두지 않는다', (tester) async {
    await pump(tester, [trip], actions: false);

    expect(find.byKey(const Key('feed-edit')), findsNothing);
    await tester.longPress(find.byType(Card));
    await tester.pumpAndSettle();
    expect(find.byType(AppSheetScaffold), findsNothing);
  });

  testWidgets('header 를 첫 칸으로 함께 스크롤한다', (tester) async {
    await pump(tester, [trip], header: const Text('머리 칸'));

    expect(
      tester.getTopLeft(find.text('머리 칸')).dy,
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

  testWidgets('모르는 스토리면 이름 없이 날짜 · 장소만', (tester) async {
    await pump(tester, [
      _entry(
        'x',
        storyId: 'gone',
        location: const EntryLocation(placeName: '애월읍', lat: 33.4, lng: 126.3),
      ),
    ]);

    expect(find.text('애월읍'), findsOneWidget);
    expect(find.text('오늘 · 오전 7:00'), findsOneWidget);
  });
}
