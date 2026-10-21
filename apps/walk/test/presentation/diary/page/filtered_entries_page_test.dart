import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/diary/prefs_diary_preferences.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/diary_view_mode.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/repository/diary_preferences.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/presentation/diary/page/filtered_entries_page.dart';
import 'package:walk/presentation/diary/widget/feed_view.dart';
import 'package:walk/presentation/diary/widget/prose_view.dart';
import 'package:walk/presentation/diary/widget/reels_view.dart';
import 'package:walk/presentation/diary/widget/view_mode_switch.dart';

import '../../../support/diary_fixtures.dart';

class _MockRepo extends Mock implements DiaryRepository {}

DiaryEntry _entry(String id, String body, {String storyId = Story.dailyId}) =>
    DiaryEntry(
      id: id,
      storyId: storyId,
      body: body,
      occurredAt: diaryT0,
      createdAt: diaryT0,
      updatedAt: diaryT0,
      media: const [],
      tags: const ['제주'],
    );

Story _story(String id, String title) => Story(
  id: id,
  title: title,
  status: StoryStatus.open,
  startedAt: diaryT0,
  createdAt: diaryT0,
);

void main() {
  late _MockRepo repo;
  late StreamController<List<DiaryEntry>> feed;
  late PrefsDiaryPreferences prefs;

  setUpAll(() => registerFallbackValue(const EntryFilter.all()));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PrefsDiaryPreferences(await SharedPreferences.getInstance());
    feed = StreamController<List<DiaryEntry>>.broadcast();
    repo = _MockRepo();
    when(repo.watchStories).thenAnswer(
      (_) => Stream.value([_story(Story.dailyId, ''), _story('jeju', '제주 여행')]),
    );
    when(() => repo.watchEntries(any())).thenAnswer((_) => feed.stream);
    getIt
      ..registerSingleton<DiaryRepository>(repo)
      ..registerSingleton<DiaryPreferences>(prefs)
      ..registerSingleton<Clock>(MutableClock(diaryT0));
  });

  tearDown(() async {
    await feed.close();
    await getIt.reset();
  });

  Future<void> pump(WidgetTester tester, EntryFilter filter) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FilteredEntriesPage(filter: filter),
      ),
    );
    await tester.pump();
  }

  Future<void> emit(WidgetTester tester, List<DiaryEntry> entries) async {
    feed.add(entries);
    await tester.pumpAndSettle();
  }

  testWidgets('태그: 제목 · 개수 · 스토리를 넘나드는 기록(스토리 이름 포함)', (tester) async {
    await pump(tester, const EntryFilter.tag('제주'));
    await emit(tester, [_entry('a', '한라산', storyId: 'jeju'), _entry('b', '귤')]);

    verify(() => repo.watchEntries(const EntryFilter.tag('제주'))).called(1);
    expect(find.widgetWithText(AppBar, '#제주'), findsOneWidget);
    expect(find.text('기록 2개'), findsOneWidget);
    expect(find.text('한라산'), findsOneWidget);
    expect(find.textContaining('제주 여행'), findsOneWidget);
    expect(find.textContaining('일상'), findsOneWidget);
  });

  testWidgets('장소: 제목은 장소 이름', (tester) async {
    await pump(tester, const EntryFilter.place('애월읍'));
    await emit(tester, [_entry('a', '노을')]);

    verify(() => repo.watchEntries(const EntryFilter.place('애월읍'))).called(1);
    expect(find.widgetWithText(AppBar, '📍 애월읍'), findsOneWidget);
    expect(find.text('기록 1개'), findsOneWidget);
  });

  testWidgets('열린 채로 기록이 늘고 줄면 따라가고, 다 사라지면 빈 상태', (tester) async {
    await pump(tester, const EntryFilter.tag('제주'));
    await emit(tester, [_entry('a', '한라산')]);
    expect(find.text('기록 1개'), findsOneWidget);

    await emit(tester, [_entry('b', '귤'), _entry('a', '한라산')]);
    expect(find.text('기록 2개'), findsOneWidget);
    expect(find.text('귤'), findsOneWidget);

    await emit(tester, const []);
    expect(find.widgetWithText(AppPlaceholder, '모아 볼 기록이 없어요'), findsOneWidget);
    expect(find.text('한라산'), findsNothing);
  });

  testWidgets('보기 모드를 바꾸면 그 모드로 그리고 저장한다', (tester) async {
    await pump(tester, const EntryFilter.tag('제주'));
    await emit(tester, [_entry('a', '한라산')]);
    expect(find.byType(ProseView), findsOneWidget);

    await tester.tap(find.text('피드'));
    await tester.pumpAndSettle();

    expect(find.byType(FeedView), findsOneWidget);
    expect(prefs.viewMode, DiaryViewMode.feed);
  });

  testWidgets('릴스는 화면을 꽉 채우고, 제목 · 개수 · 토글을 위에 얹는다(D15)', (tester) async {
    await prefs.setViewMode(DiaryViewMode.reels);
    await pump(tester, const EntryFilter.tag('제주'));
    await emit(tester, [_entry('a', '한라산')]);

    expect(find.byType(ReelsView), findsOneWidget);
    final screen = tester.getRect(find.byType(FilteredEntriesPage));
    expect(tester.getRect(find.byType(ReelsView)), screen);
    expect(find.widgetWithText(AppBar, '#제주'), findsOneWidget);
    expect(find.text('기록 1개'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.byType(ViewModeSwitch)).dy,
      lessThan(tester.getBottomLeft(find.byType(ReelsView)).dy),
    );

    await tester.tap(find.text('줄글'));
    await tester.pumpAndSettle();

    expect(find.byType(ProseView), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(ProseView)).dy,
      greaterThan(tester.getBottomLeft(find.byType(ViewModeSwitch)).dy),
    );
  });

  testWidgets('읽지 못하면 오류 안내', (tester) async {
    await pump(tester, const EntryFilter.tag('제주'));
    feed.addError(Exception('db'));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(AppPlaceholder, '기록을 불러오지 못했어요'),
      findsOneWidget,
    );
  });
}
