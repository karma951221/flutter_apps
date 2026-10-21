import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/presentation/diary/page/filtered_entries_page.dart';
import 'package:walk/presentation/diary/viewer/story_viewer_page.dart';
import 'package:walk/presentation/diary/widget/entry_grid.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';

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
  late DiaryLockCubit lock;

  setUpAll(() => registerFallbackValue(const EntryFilter.all()));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final lockRepo = PrefsLockRepository(await SharedPreferences.getInstance());
    final clock = MutableClock(diaryT0);
    lock = DiaryLockCubit(lockRepo, FakeDeviceAuth(), clock, MediaPickGuard())
      ..start();
    feed = StreamController<List<DiaryEntry>>.broadcast();
    repo = _MockRepo();
    when(repo.watchStories).thenAnswer(
      (_) => Stream.value([_story(Story.dailyId, ''), _story('jeju', '제주 여행')]),
    );
    when(() => repo.watchEntries(any())).thenAnswer((_) => feed.stream);
    getIt
      ..registerSingleton<DiaryRepository>(repo)
      ..registerSingleton<Clock>(clock)
      ..registerSingleton<LockRepository>(lockRepo)
      ..registerSingleton<DeviceAuth>(FakeDeviceAuth());
  });

  tearDown(() async {
    await feed.close();
    await lock.close();
    await getIt.reset();
  });

  /// 셸처럼 잠금을 내려 주는 첫 화면 위에 모아보기를 띄운다.
  Future<void> pump(WidgetTester tester, EntryFilter filter) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: [appRouteObserver],
        home: BlocProvider.value(
          value: lock,
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => openFilteredEntries(context, filter),
                  child: const Text('home'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
  }

  Future<void> emit(WidgetTester tester, List<DiaryEntry> entries) async {
    feed.add(entries);
    await tester.pumpAndSettle();
  }

  testWidgets('태그: 제목 · 개수 · 그리드', (tester) async {
    await pump(tester, const EntryFilter.tag('제주'));
    await emit(tester, [_entry('a', '한라산', storyId: 'jeju'), _entry('b', '귤')]);

    verify(() => repo.watchEntries(const EntryFilter.tag('제주'))).called(1);
    expect(find.widgetWithText(AppBar, '#제주'), findsOneWidget);
    expect(find.text('기록 2개'), findsOneWidget);
    expect(find.byType(SliverEntryGrid), findsOneWidget);
    expect(find.byKey(const ValueKey('grid-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('grid-b')), findsOneWidget);
    expect(find.widgetWithText(AppButton, '▶ 보기'), findsOneWidget);
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
    expect(find.byKey(const ValueKey('grid-b')), findsOneWidget);

    await emit(tester, const []);
    expect(find.widgetWithText(AppPlaceholder, '모아 볼 기록이 없어요'), findsOneWidget);
    expect(find.byKey(const ValueKey('grid-a')), findsNothing);
    expect(find.widgetWithText(AppButton, '▶ 보기'), findsNothing);
  });

  Future<void> settleViewer(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('▶ 보기 → 모아보기 소스 뷰어', (tester) async {
    await pump(tester, const EntryFilter.tag('제주'));
    await emit(tester, [_entry('a', '한라산'), _entry('b', '귤')]);

    await tester.tap(find.widgetWithText(AppButton, '▶ 보기'));
    await settleViewer(tester);

    final viewer = tester.widget<StoryViewerPage>(find.byType(StoryViewerPage));
    expect(
      viewer.source,
      const ViewerSource.filter(EntryFilter.tag('제주'), '#제주'),
    );
    expect(viewer.fromStart, isTrue);
    expect(viewer.entryId, isNull);
  });

  testWidgets('칸 탭 → 그 기록부터', (tester) async {
    await pump(tester, const EntryFilter.place('애월읍'));
    await emit(tester, [_entry('a', '노을'), _entry('b', '바다')]);

    await tester.tap(find.byKey(const ValueKey('grid-b')));
    await settleViewer(tester);

    final viewer = tester.widget<StoryViewerPage>(find.byType(StoryViewerPage));
    expect(
      viewer.source,
      const ViewerSource.filter(EntryFilter.place('애월읍'), '📍 애월읍'),
    );
    expect(viewer.entryId, 'b');
    expect(viewer.fromStart, isFalse);
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
