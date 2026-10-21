import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/diary/usecase/diary_use_case.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/presentation/diary/page/all_stories_page.dart';
import 'package:walk/presentation/diary/page/story_page.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';

class _MockRepo extends Mock implements DiaryRepository {}

class _MockUseCase extends Mock implements DiaryUseCase {}

class _MockStore extends Mock implements MediaStore {}

Story _story(String id, String title, {DateTime? endedAt}) => Story(
  id: id,
  title: title,
  status: endedAt == null ? StoryStatus.open : StoryStatus.closed,
  startedAt: diaryT0,
  endedAt: endedAt,
  createdAt: diaryT0,
);

DiaryEntry _entry(
  String id, {
  String storyId = Story.dailyId,
  DateTime? occurredAt,
}) => DiaryEntry(
  id: id,
  storyId: storyId,
  body: '글 $id',
  occurredAt: occurredAt ?? diaryT0,
  createdAt: diaryT0,
  updatedAt: diaryT0,
  media: const [],
  tags: const [],
);

void main() {
  late _MockRepo repo;
  late _MockUseCase useCase;
  late List<DiaryEntry> all;
  late MutableClock clock;
  late DiaryLockCubit lock;

  setUpAll(() {
    registerFallbackValue(const EntryFilter.all());
    registerFallbackValue(_story('x', 'x'));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    all = [
      _entry('j1', storyId: 'jeju'),
      _entry('j2', storyId: 'jeju'),
      _entry('d1'),
    ];
    repo = _MockRepo();
    when(repo.watchStories).thenAnswer(
      (_) => Stream.value([
        _story(Story.dailyId, ''),
        _story('jeju', '제주 여행'),
        _story('busan', '부산', endedAt: diaryT0),
      ]),
    );
    when(() => repo.watchEntries(any())).thenAnswer((inv) {
      final filter = inv.positionalArguments.single as EntryFilter;
      return Stream.value([
        for (final e in all)
          if (filter is! StoryEntries || e.storyId == filter.storyId) e,
      ]);
    });
    useCase = _MockUseCase();
    final store = _MockStore();
    when(
      () => store.resolve(any()),
    ).thenAnswer((inv) => File('/fake/${inv.positionalArguments.single}'));
    clock = MutableClock(diaryT0);
    final lockRepo = PrefsLockRepository(await SharedPreferences.getInstance());
    lock = DiaryLockCubit(lockRepo, FakeDeviceAuth(), clock, MediaPickGuard())
      ..start();
    getIt
      ..registerSingleton<DiaryRepository>(repo)
      ..registerSingleton<DiaryUseCase>(useCase)
      ..registerSingleton<MediaStore>(store)
      ..registerSingleton<Clock>(clock)
      ..registerSingleton<LockRepository>(lockRepo)
      ..registerSingleton<DeviceAuth>(FakeDeviceAuth());
  });

  tearDown(() async {
    await lock.close();
    await getIt.reset();
  });

  Future<void> open(WidgetTester tester) async {
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
                  onPressed: () => openAllStories(context),
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

  Finder card(String id) => find.byKey(ValueKey('story-card-$id'));

  testWidgets('진행 중 · 지난 구역 카드, 탭 → 스토리 페이지', (tester) async {
    await open(tester);

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('모든 스토리')),
      findsOneWidget,
    );
    expect(find.text('진행 중'), findsOneWidget);
    expect(find.text('지난 스토리'), findsOneWidget);
    expect(
      find.descendant(of: card(Story.dailyId), matching: find.text('일상')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card('jeju'), matching: find.text('기록 2개')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card('busan'), matching: find.text('기록 0개')),
      findsOneWidget,
    );
    // 일상 · 제주는 진행 중 구역, 부산은 지난 스토리 구역 아래.
    final past = tester.getTopLeft(find.text('지난 스토리')).dy;
    expect(tester.getTopLeft(card('jeju')).dy, lessThan(past));
    expect(tester.getTopLeft(card(Story.dailyId)).dy, lessThan(past));
    expect(tester.getTopLeft(card('busan')).dy, greaterThan(past));
    // 2열.
    expect(
      tester.getTopLeft(card(Story.dailyId)).dy,
      tester.getTopLeft(card('jeju')).dy,
    );

    await tester.tap(card('jeju'));
    await tester.pumpAndSettle();

    expect(tester.widget<StoryPage>(find.byType(StoryPage)).storyId, 'jeju');
  });

  testWidgets('지난 스토리가 없으면 그 구역을 두지 않는다', (tester) async {
    when(
      repo.watchStories,
    ).thenAnswer((_) => Stream.value([_story(Story.dailyId, '')]));
    await open(tester);

    expect(find.text('진행 중'), findsOneWidget);
    expect(find.text('지난 스토리'), findsNothing);
  });

  testWidgets('＋ 만들기 · 지난 기간이면 일상 옮기기 제안', (tester) async {
    final created = Story(
      id: 'chuseok',
      title: '추석',
      status: StoryStatus.open,
      startedAt: DateTime(2026, 10, 3),
      createdAt: diaryT0,
    );
    when(
      () => repo.createStory(
        title: any(named: 'title'),
        startedAt: any(named: 'startedAt'),
        endedAt: any(named: 'endedAt'),
      ),
    ).thenAnswer((_) async => Ok(created));
    when(
      () => repo.entriesBetween(any(), any(), storyId: any(named: 'storyId')),
    ).thenAnswer(
      (_) async => [
        _entry('a', occurredAt: DateTime(2026, 10, 4)),
        _entry('b', occurredAt: DateTime(2026, 10, 3)),
      ],
    );
    when(
      () => repo.moveEntries(any(), any()),
    ).thenAnswer((_) async => const Ok(null));
    await open(tester);

    await tester.tap(find.byTooltip('새 스토리'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '추석');
    await tester.tap(find.textContaining('시작일'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3'));
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, '만들기'));
    await tester.pumpAndSettle();

    verify(
      () => repo.createStory(
        title: '추석',
        startedAt: DateTime(2026, 10, 3),
        endedAt: null,
      ),
    ).called(1);
    verify(
      () => repo.entriesBetween(
        DateTime(2026, 10, 3),
        diaryT0,
        storyId: Story.dailyId,
      ),
    ).called(1);
    expect(find.text("이 기간의 '일상' 기록을 옮길까요?"), findsOneWidget);
    expect(find.text('글 a'), findsOneWidget);
    expect(find.text('글 b'), findsOneWidget);

    // 하나를 빼고 옮긴다.
    await tester.tap(find.text('글 b'));
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, '1개 옮기기'));
    await tester.pumpAndSettle();

    verify(() => repo.moveEntries(['a'], 'chuseok')).called(1);
    expect(find.widgetWithText(SnackBar, '기록 1개를 옮겼어요'), findsOneWidget);
  });

  testWidgets('오늘 시작하는 스토리는 옮기기를 제안하지 않는다', (tester) async {
    when(
      () => repo.createStory(
        title: any(named: 'title'),
        startedAt: any(named: 'startedAt'),
        endedAt: any(named: 'endedAt'),
      ),
    ).thenAnswer((_) async => Ok(_story('new', '새 여행')));
    when(
      () => repo.entriesBetween(any(), any(), storyId: any(named: 'storyId')),
    ).thenAnswer((_) async => [_entry('a')]);
    await open(tester);

    await tester.tap(find.byTooltip('새 스토리'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '새 여행');
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, '만들기'));
    await tester.pumpAndSettle();

    verifyNever(
      () => repo.entriesBetween(any(), any(), storyId: any(named: 'storyId')),
    );
    expect(find.text("이 기간의 '일상' 기록을 옮길까요?"), findsNothing);
    verify(
      () => repo.createStory(
        title: '새 여행',
        startedAt: DateTime(2026, 10, 10),
        endedAt: null,
      ),
    ).called(1);
  });
}
