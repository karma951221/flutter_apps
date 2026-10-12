import 'dart:io';

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
import 'package:walk/domain/diary/entity/diary_view_mode.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/location/place_source.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/repository/diary_preferences.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/diary/usecase/diary_use_case.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/presentation/diary/page/diary_search_page.dart';
import 'package:walk/presentation/diary/page/diary_tab.dart';
import 'package:walk/presentation/diary/page/entry_detail_page.dart';
import 'package:walk/presentation/diary/page/entry_editor_page.dart';
import 'package:walk/presentation/diary/page/story_manage_page.dart';
import 'package:walk/presentation/diary/page/trash_page.dart';
import 'package:walk/presentation/diary/widget/entry_media_view.dart';
import 'package:walk/presentation/diary/widget/feed_view.dart';
import 'package:walk/presentation/diary/widget/prose_view.dart';
import 'package:walk/presentation/diary/widget/reels_view.dart';
import 'package:walk/presentation/diary/widget/story_avatar.dart';
import 'package:walk/presentation/diary/widget/story_bar.dart';
import 'package:walk/presentation/diary/widget/story_header.dart';
import 'package:walk/presentation/diary/media_picker.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';
import 'package:walk/presentation/lock/widget/pin_pad.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';

class _MockRepo extends Mock implements DiaryRepository {}

class _MockUseCase extends Mock implements DiaryUseCase {}

class _MockStore extends Mock implements MediaStore {}

class _MockPlaces extends Mock implements PlaceSource {}

class _MockPicker extends Mock implements MediaPicker {}

Story _story(String id, String title, {DateTime? lastPostedAt}) => Story(
  id: id,
  title: title,
  status: StoryStatus.open,
  startedAt: diaryT0,
  lastPostedAt: lastPostedAt,
  createdAt: diaryT0,
);

DiaryEntry _entry(String body, {String storyId = Story.dailyId}) => DiaryEntry(
  id: body,
  storyId: storyId,
  body: body,
  occurredAt: diaryT0,
  createdAt: diaryT0,
  updatedAt: diaryT0,
  media: const [],
  tags: const [],
);

void main() {
  late _MockRepo repo;
  late _MockUseCase useCase;
  late PrefsLockRepository lockRepo;
  late DiaryLockCubit lock;
  late List<Story> stories;
  late Map<EntryFilter, List<DiaryEntry>> entries;

  setUpAll(() => registerFallbackValue(const EntryFilter.all()));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    stories = [_story(Story.dailyId, '')];
    entries = {};
    repo = _MockRepo();
    when(repo.watchStories).thenAnswer((_) => Stream.value(stories));
    when(() => repo.watchEntries(any())).thenAnswer(
      (inv) => Stream.value(
        entries[inv.positionalArguments.single as EntryFilter] ?? const [],
      ),
    );
    useCase = _MockUseCase();
    when(useCase.maintain).thenAnswer((_) async {});
    lockRepo = PrefsLockRepository(prefs);
    final clock = MutableClock(diaryT0);
    lock = DiaryLockCubit(lockRepo, FakeDeviceAuth(), clock, MediaPickGuard());
    getIt
      ..registerSingleton<DiaryRepository>(repo)
      ..registerSingleton<DiaryPreferences>(PrefsDiaryPreferences(prefs))
      ..registerSingleton<DiaryUseCase>(useCase)
      ..registerSingleton<LockRepository>(lockRepo)
      ..registerSingleton<DeviceAuth>(FakeDeviceAuth())
      ..registerSingleton<Clock>(clock);
  });

  tearDown(() async {
    await lock.close();
    await getIt.reset();
  });

  Widget app({bool active = true}) => MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider.value(
      value: lock,
      child: DiaryTab(active: active),
    ),
  );

  Future<void> pump(WidgetTester tester, {bool active = true}) async {
    lock.start();
    await tester.pumpWidget(app(active: active));
    await tester.pumpAndSettle();
  }

  List<String> barLabels(WidgetTester tester) {
    final avatars =
        tester.widgetList<StoryAvatar>(find.byType(StoryAvatar)).toList()..sort(
          (a, b) => tester
              .getTopLeft(find.byWidget(a))
              .dx
              .compareTo(tester.getTopLeft(find.byWidget(b)).dx),
        );
    return [for (final a in avatars) a.label];
  }

  testWidgets('잠긴 동안 타임라인 위젯이 트리에 없고, 풀면 스토리 바가 보인다', (tester) async {
    await lockRepo.setSecret(LockMethod.pin, '1234');
    await lockRepo.saveConfig(const LockConfig(enabled: true));
    entries[const EntryFilter.all()] = [_entry('비밀 기록')];
    await pump(tester);

    expect(find.byType(StoryBar, skipOffstage: false), findsNothing);
    expect(find.text('비밀 기록', skipOffstage: false), findsNothing);
    expect(find.byType(PinPad), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byIcon(Icons.search), findsNothing);

    for (final d in '1234'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, d));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.byType(StoryBar), findsOneWidget);
    expect(find.text('비밀 기록'), findsOneWidget);
  });

  testWidgets('스토리 바: 전체 → 열린 스토리 lastPostedAt 순 → 보관함, 기본 스토리는 일상', (
    tester,
  ) async {
    stories = [
      _story(Story.dailyId, '', lastPostedAt: diaryT0),
      _story(
        'jeju',
        '제주 여행',
        lastPostedAt: diaryT0.add(const Duration(days: 1)),
      ),
      Story(
        id: 'busan',
        title: '부산',
        status: StoryStatus.closed,
        startedAt: diaryT0,
        endedAt: diaryT0,
        createdAt: diaryT0,
      ),
    ];
    await pump(tester);

    expect(barLabels(tester), ['전체', '제주 여행', '일상', '보관함']);
  });

  testWidgets('기록이 없으면 빈 상태 안내', (tester) async {
    await pump(tester);

    expect(find.widgetWithText(AppPlaceholder, '아직 기록이 없어요'), findsOneWidget);
  });

  testWidgets('스토리를 누르면 그 스토리 기록으로 바뀐다', (tester) async {
    stories = [_story(Story.dailyId, ''), _story('jeju', '제주 여행')];
    entries[const EntryFilter.all()] = [_entry('출근'), _entry('바다')];
    entries[const EntryFilter.story('jeju')] = [_entry('바다', storyId: 'jeju')];
    await pump(tester);
    expect(find.text('출근'), findsOneWidget);

    await tester.tap(find.text('제주 여행'));
    await tester.pumpAndSettle();

    expect(find.text('출근'), findsNothing);
    expect(find.text('바다'), findsOneWidget);
  });

  Finder inHeader(String text) => find.descendant(
    of: find.byType(StoryHeader),
    matching: find.textContaining(text),
  );

  testWidgets('머리: 전체는 이름만, 스토리를 고르면 이름 · 기간', (tester) async {
    stories = [
      _story(Story.dailyId, ''),
      _story('jeju', '제주 여행'),
      Story(
        id: 'busan',
        title: '부산',
        status: StoryStatus.closed,
        startedAt: DateTime(2026, 10, 1),
        endedAt: DateTime(2026, 10, 3),
        createdAt: diaryT0,
      ),
    ];
    await pump(tester);
    expect(inHeader('전체'), findsOneWidget);
    expect(inHeader('~'), findsNothing);

    await tester.tap(find.text('제주 여행'));
    await tester.pumpAndSettle();
    expect(inHeader('제주 여행 · 10월 10일 ~ 진행 중'), findsOneWidget);

    await tester.tap(find.text('보관함'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('부산'));
    await tester.pumpAndSettle();
    expect(inHeader('부산 · 10월 1일 ~ 10월 3일'), findsOneWidget);
  });

  testWidgets('보기 모드 토글로 줄글 · 피드 · 릴스를 바꾼다', (tester) async {
    entries[const EntryFilter.all()] = [_entry('출근')];
    await pump(tester);
    expect(find.byType(ProseView), findsOneWidget);

    await tester.tap(find.text('피드'));
    await tester.pumpAndSettle();
    expect(find.byType(FeedView), findsOneWidget);
    expect(find.text('출근'), findsOneWidget);

    await tester.tap(find.text('릴스'));
    await tester.pumpAndSettle();
    expect(find.byType(ReelsView), findsOneWidget);
    expect(getIt<DiaryPreferences>().viewMode, DiaryViewMode.reels);
  });

  group('릴스', () {
    setUp(() async {
      await getIt<DiaryPreferences>().setViewMode(DiaryViewMode.reels);
      final store = _MockStore();
      when(
        () => store.resolve(any()),
      ).thenAnswer((inv) => File('/fake/${inv.positionalArguments.single}'));
      getIt.registerSingleton<MediaStore>(store);
      entries[const EntryFilter.all()] = [
        _entry('바다').copyWith(media: [photoMedia('p1')]),
      ];
    });

    testWidgets('탭 몸통을 꽉 채우고, 스토리 바 · 앱바 대신 머리 · 토글을 위에 얹는다', (tester) async {
      await pump(tester);

      expect(find.byType(ReelsView), findsOneWidget);
      expect(find.byType(StoryBar), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      final body = tester.getRect(find.byType(DiaryTab));
      expect(tester.getRect(find.byType(ReelsView)), body);
      expect(inHeader('전체'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(StoryHeader)).dy,
        lessThan(tester.getBottomLeft(find.byType(ReelsView)).dy),
      );

      await tester.tap(find.text('줄글'));
      await tester.pumpAndSettle();

      expect(find.byType(ProseView), findsOneWidget);
      expect(find.byType(StoryBar), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('탭이 가려지면 재생을 멈춘다', (tester) async {
      await pump(tester);
      bool playing() =>
          tester.widget<MediaPager>(find.byType(MediaPager)).playing;
      expect(playing(), isTrue);

      await tester.pumpWidget(app(active: false));
      await tester.pumpAndSettle();
      expect(playing(), isFalse);

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(playing(), isTrue);
    });
  });

  group('작성 화면 열기', () {
    setUp(() {
      final places = _MockPlaces();
      when(places.current).thenAnswer((_) async => null);
      when(
        () => repo.watchTagCounts(query: any(named: 'query')),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => repo.watchPlaceCounts(query: any(named: 'query')),
      ).thenAnswer((_) => Stream.value(const []));
      final store = _MockStore();
      when(() => store.resolve(any())).thenAnswer((_) => File('/fake'));
      getIt
        ..registerSingleton<PlaceSource>(places)
        ..registerSingleton<MediaPicker>(_MockPicker())
        ..registerSingleton<MediaStore>(store);
    });

    testWidgets('＋ 를 누르면 새 기록 화면', (tester) async {
      await pump(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final scope = tester.widget<EntryEditorScope>(
        find.byType(EntryEditorScope),
      );
      expect(scope.editingId, isNull);
      expect(find.byType(EntryEditorPage), findsOneWidget);
      expect(find.text('새 기록'), findsOneWidget);
    });

    testWidgets('기록을 누르면 그 기록 상세(R18)', (tester) async {
      final entry = _entry('출근');
      entries[const EntryFilter.all()] = [entry];
      when(() => repo.entry('출근')).thenAnswer((_) async => Ok(entry));
      await pump(tester);

      await tester.tap(find.text('출근'));
      await tester.pumpAndSettle();

      final detail = tester.widget<EntryDetailPage>(
        find.byType(EntryDetailPage),
      );
      expect(detail.entryId, '출근');
      expect(find.byType(EntryEditorPage), findsNothing);
    });

    testWidgets('앱바 ⋮ → 스토리 관리', (tester) async {
      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('스토리 관리'));
      await tester.pumpAndSettle();

      expect(find.byType(StoryManagePage), findsOneWidget);
    });

    testWidgets('앱바 ⋮ → 휴지통', (tester) async {
      when(repo.watchTrash).thenAnswer((_) => Stream.value(const []));
      await pump(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('휴지통'));
      await tester.pumpAndSettle();

      expect(find.byType(TrashPage), findsOneWidget);
    });

    testWidgets('릴스에서도 🔍 · ⋮ 를 누를 수 있다(R25)', (tester) async {
      when(repo.watchTrash).thenAnswer((_) => Stream.value(const []));
      await getIt<DiaryPreferences>().setViewMode(DiaryViewMode.reels);
      entries[const EntryFilter.all()] = [_entry('바다')];
      await pump(tester);
      expect(find.byType(AppBar), findsNothing);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('스토리 관리'), findsOneWidget);
      await tester.tap(find.text('휴지통'));
      await tester.pumpAndSettle();
      expect(find.byType(TrashPage), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.byType(DiarySearchPage), findsOneWidget);
    });

    testWidgets('앱바 🔍 → 스토리 결과를 누르면 타임라인이 그 스토리를 고른다', (tester) async {
      stories = [_story(Story.dailyId, ''), _story('jeju', '제주 여행')];
      entries[const EntryFilter.all()] = [_entry('출근')];
      entries[const EntryFilter.story('jeju')] = [
        _entry('바다', storyId: 'jeju'),
      ];
      when(
        () =>
            repo.watchStoryMatches(any(), dailyTitle: any(named: 'dailyTitle')),
      ).thenAnswer(
        (_) => Stream.value([(story: _story('jeju', '제주 여행'), count: 1)]),
      );
      await pump(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.byType(DiarySearchPage), findsOneWidget);
      await tester.tap(find.widgetWithText(Tab, '스토리'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '제주');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppListTile, '제주 여행'));
      await tester.pumpAndSettle();

      expect(find.byType(DiarySearchPage), findsNothing);
      expect(find.text('바다'), findsOneWidget);
      expect(find.text('출근'), findsNothing);
    });

    testWidgets('릴스에서도 ＋ 가 있고 위의 머리 · 토글을 가리지 않는다', (tester) async {
      await getIt<DiaryPreferences>().setViewMode(DiaryViewMode.reels);
      entries[const EntryFilter.all()] = [_entry('바다')];
      await pump(tester);

      final fab = tester.getRect(find.byType(FloatingActionButton));
      final header = tester.getRect(find.byType(StoryHeader));
      expect(fab.overlaps(header), isFalse);
    });
  });

  testWidgets('기록을 읽지 못하면 오류 안내', (tester) async {
    when(
      () => repo.watchEntries(any()),
    ).thenAnswer((_) => Stream.error(Exception('db')));
    await pump(tester);

    expect(
      find.widgetWithText(AppPlaceholder, '기록을 불러오지 못했어요'),
      findsOneWidget,
    );
  });

  testWidgets('탭이 보이게 될 때마다 정리(maintain)를 한 번 부른다', (tester) async {
    await pump(tester, active: false);
    verifyNever(useCase.maintain);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    verify(useCase.maintain).called(1);

    // 보이는 채 다시 그려도 부르지 않는다.
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    verifyNever(useCase.maintain);

    await tester.pumpWidget(app(active: false));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    verify(useCase.maintain).called(1);
  });

  testWidgets('처음부터 보이는 탭이면 시작할 때 정리를 부른다', (tester) async {
    await pump(tester);

    verify(useCase.maintain).called(1);
  });

  testWidgets('정리가 실패해도 화면은 그대로다', (tester) async {
    when(useCase.maintain).thenAnswer((_) => Future.error(Exception('io')));
    await pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(StoryBar), findsOneWidget);
  });

  testWidgets('스토리 바에 표지 사진을 보인다(R17)', (tester) async {
    final store = _MockStore();
    when(
      () => store.resolve(any()),
    ).thenAnswer((inv) => File('/fake/${inv.positionalArguments.single}'));
    getIt.registerSingleton<MediaStore>(store);
    stories = [_story(Story.dailyId, ''), _story('jeju', '제주 여행')];
    entries[const EntryFilter.all()] = [
      _entry('바다', storyId: 'jeju').copyWith(media: [videoMedia('v1')]),
    ];
    await pump(tester);

    StoryAvatar avatar(String label) => tester.widget<StoryAvatar>(
      find.byWidgetPredicate((w) => w is StoryAvatar && w.label == label),
    );
    expect(avatar('제주 여행').image?.path, '/fake/media/v1.thumb.jpg');
    expect(avatar('일상').image, isNull);
  });
}
