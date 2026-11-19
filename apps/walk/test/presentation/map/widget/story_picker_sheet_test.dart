import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/presentation/diary/widget/story_avatar.dart';
import 'package:walk/presentation/diary/widget/story_row.dart';
import 'package:walk/presentation/map/widget/story_picker_sheet.dart';

import '../../../support/diary_fixtures.dart';

class _MockRepo extends Mock implements DiaryRepository {}

class _MockStore extends Mock implements MediaStore {}

Story _story(String id, String title, {bool open = true}) => Story(
  id: id,
  title: title,
  status: open ? StoryStatus.open : StoryStatus.closed,
  startedAt: DateTime(2026, 10, 1),
  endedAt: open ? null : DateTime(2026, 10, 3),
  createdAt: DateTime(2026, 10, 1),
);

DiaryEntry _entry(String id, String storyId, {bool photo = false}) =>
    DiaryEntry(
      id: id,
      storyId: storyId,
      body: id,
      occurredAt: DateTime(2026, 10, 2),
      createdAt: DateTime(2026, 10, 2),
      updatedAt: DateTime(2026, 10, 2),
      media: [if (photo) photoMedia('m-$id')],
      tags: const [],
    );

void main() {
  setUpAll(() => registerFallbackValue(const EntryFilter.all()));

  setUp(() {
    final repo = _MockRepo();
    when(repo.watchStories).thenAnswer(
      (_) => Stream.value([
        _story('jeju', '제주 여행'),
        _story('old', '지난 여행', open: false),
      ]),
    );
    when(() => repo.watchEntries(any())).thenAnswer(
      (_) => Stream.value([
        _entry('a', 'jeju', photo: true),
        _entry('b', 'jeju'),
        _entry('c', 'old'),
      ]),
    );
    final store = _MockStore();
    when(
      () => store.resolve(any()),
    ).thenAnswer((inv) => File('/fake/${inv.positionalArguments.single}'));
    getIt
      ..registerSingleton<DiaryRepository>(repo)
      ..registerSingleton<MediaStore>(store)
      ..registerSingleton<Clock>(MutableClock(DateTime(2026, 11, 1)));
  });
  tearDown(() => getIt.reset());

  testWidgets('행마다 표지와 기록 수가 있고, 누르면 그 스토리를 고른다', (tester) async {
    Story? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => picked = await showStoryPicker(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final jeju = find.byKey(const ValueKey('story-pick-jeju'));
    final covers = find.descendant(
      of: jeju,
      matching: find.byType(StoryCoverCircle),
    );
    expect(
      tester.widget<StoryCoverCircle>(covers).image?.path,
      '/fake/media/m-a.jpg',
    );
    expect(find.textContaining('기록 2개'), findsOneWidget);
    expect(find.textContaining('기록 1개'), findsOneWidget);

    await tester.tap(find.text('지난 여행'));
    await tester.pumpAndSettle();
    expect(picked?.id, 'old');
  });

  testWidgets('행은 StoryRow — 기간 끝이 진행 중 · 날짜로 보인다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showStoryPicker(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(StoryRow), findsNWidgets(2));
    expect(find.textContaining('진행 중'), findsOneWidget);
  });
}
