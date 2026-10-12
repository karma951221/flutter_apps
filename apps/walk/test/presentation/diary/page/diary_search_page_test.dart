import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/diary/prefs_diary_preferences.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/named_count.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/repository/diary_preferences.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/presentation/diary/page/diary_search_page.dart';
import 'package:walk/presentation/diary/page/filtered_entries_page.dart';
import 'package:walk/presentation/diary/widget/highlighted_text.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';

class _MockRepo extends Mock implements DiaryRepository {}

DiaryEntry _entry(String id, String body) => DiaryEntry(
  id: id,
  storyId: Story.dailyId,
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

NamedCount _count(String name, int count) =>
    NamedCount(name: name, count: count, lastUsedAt: diaryT0);

void main() {
  late _MockRepo repo;
  late DiaryLockCubit lock;
  late Map<EntryFilter, List<DiaryEntry>> entries;

  setUpAll(() => registerFallbackValue(const EntryFilter.all()));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    entries = {};
    repo = _MockRepo();
    when(repo.watchStories).thenAnswer(
      (_) => Stream.value([_story(Story.dailyId, ''), _story('jeju', '제주 여행')]),
    );
    when(() => repo.watchEntries(any())).thenAnswer(
      (inv) => Stream.value(
        entries[inv.positionalArguments.single as EntryFilter] ?? const [],
      ),
    );
    when(
      () => repo.watchTagCounts(query: any(named: 'query')),
    ).thenAnswer((_) => Stream.value([_count('제주', 3), _count('바다', 1)]));
    when(
      () => repo.watchPlaceCounts(query: any(named: 'query')),
    ).thenAnswer((_) => Stream.value([_count('애월읍', 2)]));
    when(
      () => repo.watchStoryMatches(any(), dailyTitle: any(named: 'dailyTitle')),
    ).thenAnswer(
      (_) => Stream.value([(story: _story('jeju', '제주 여행'), count: 4)]),
    );
    final clock = MutableClock(diaryT0);
    lock = DiaryLockCubit(
      PrefsLockRepository(prefs),
      FakeDeviceAuth(),
      clock,
      MediaPickGuard(),
    );
    getIt
      ..registerSingleton<DiaryRepository>(repo)
      ..registerSingleton<DiaryPreferences>(PrefsDiaryPreferences(prefs))
      ..registerSingleton<Clock>(clock);
  });

  tearDown(() async {
    await lock.close();
    await getIt.reset();
  });

  /// 검색 화면을 띄우는 바탕. 닫힐 때 돌려준 값을 [picked] 에 담는다.
  Future<List<String?>> pump(WidgetTester tester) async {
    final picked = <String?>[];
    lock.start();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: lock,
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    picked.add(await openDiarySearch(context)),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    return picked;
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  Future<void> tab(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(Tab, label));
    await tester.pumpAndSettle();
  }

  testWidgets('탭 4개, 처음엔 글 탭에서 입력을 안내한다', (tester) async {
    await pump(tester);

    for (final label in ['글', '스토리', '해시태그', '장소']) {
      expect(find.widgetWithText(Tab, label), findsOneWidget);
    }
    expect(
      find.widgetWithText(AppPlaceholder, '글에서 찾을 말을 입력해 보세요'),
      findsOneWidget,
    );
    verifyNever(() => repo.watchEntries(any()));
  });

  testWidgets('탭 전환: 해시태그 · 장소는 입력 전에도 추천과 개수를 보인다', (tester) async {
    await pump(tester);

    await tab(tester, '해시태그');
    expect(find.widgetWithText(AppListTile, '#제주'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(AppListTile, '#제주'),
        matching: find.text('기록 3개'),
      ),
      findsOneWidget,
    );
    expect(find.text('기록 1개'), findsOneWidget);

    await tab(tester, '장소');
    expect(find.widgetWithText(AppListTile, '애월읍'), findsOneWidget);
    expect(find.text('기록 2개'), findsOneWidget);
    expect(find.text('#제주'), findsNothing);

    await tab(tester, '스토리');
    expect(
      find.widgetWithText(AppPlaceholder, '찾을 스토리 이름을 입력해 보세요'),
      findsOneWidget,
    );
  });

  testWidgets('글 결과는 일치한 부분을 굵게 그린다', (tester) async {
    entries[const EntryFilter.body('바다')] = [_entry('a', '아침 바다와 저녁 바다')];
    await pump(tester);

    await type(tester, ' 바다 ');

    final text = tester.widget<Text>(
      find.descendant(
        of: find.byType(HighlightedText),
        matching: find.byType(Text),
      ),
    );
    final bold = <String>[];
    text.textSpan!.visitChildren((span) {
      if (span is TextSpan && span.style?.fontWeight == FontWeight.bold) {
        bold.add(span.text!);
      }
      return true;
    });
    expect(bold, ['바다', '바다']);
    expect(find.text('아침 바다와 저녁 바다', findRichText: true), findsOneWidget);
  });

  testWidgets('결과가 없으면 없다고 안내한다', (tester) async {
    await pump(tester);

    await type(tester, '없는 말');

    expect(find.widgetWithText(AppPlaceholder, '찾는 결과가 없어요'), findsOneWidget);
  });

  testWidgets('스토리 결과를 누르면 그 스토리 id 를 들고 닫힌다', (tester) async {
    final picked = await pump(tester);

    await tab(tester, '스토리');
    await type(tester, '제주');
    expect(find.text('기록 4개'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppListTile, '제주 여행'));
    await tester.pumpAndSettle();

    expect(picked, ['jeju']);
    expect(find.byType(DiarySearchPage), findsNothing);
  });

  testWidgets('태그 추천을 누르면 그 태그 모아보기가 열린다', (tester) async {
    entries[const EntryFilter.tag('제주')] = [_entry('a', '한라산')];
    await pump(tester);

    await tab(tester, '해시태그');
    await tester.tap(find.widgetWithText(AppListTile, '#제주'));
    await tester.pumpAndSettle();

    expect(find.byType(FilteredEntriesPage), findsOneWidget);
    expect(find.text('한라산'), findsOneWidget);
  });

  testWidgets('장소 추천을 누르면 그 장소 모아보기가 열린다', (tester) async {
    entries[const EntryFilter.place('애월읍')] = [_entry('a', '노을')];
    await pump(tester);

    await tab(tester, '장소');
    await tester.tap(find.widgetWithText(AppListTile, '애월읍'));
    await tester.pumpAndSettle();

    expect(find.byType(FilteredEntriesPage), findsOneWidget);
    expect(find.text('노을'), findsOneWidget);
  });

  testWidgets('조회에 실패하면 오류 안내', (tester) async {
    when(
      () => repo.watchTagCounts(query: any(named: 'query')),
    ).thenAnswer((_) => Stream.error(Exception('db')));
    await pump(tester);

    await tab(tester, '해시태그');

    expect(
      find.widgetWithText(AppPlaceholder, '기록을 불러오지 못했어요'),
      findsOneWidget,
    );
  });
}
