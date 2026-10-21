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
import 'package:walk/data/diary/prefs_diary_preferences.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
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
import 'package:walk/presentation/diary/page/all_stories_page.dart';
import 'package:walk/presentation/diary/page/diary_search_page.dart';
import 'package:walk/presentation/diary/page/diary_tab.dart';
import 'package:walk/presentation/diary/page/entry_editor_page.dart';
import 'package:walk/presentation/diary/page/story_form_sheet.dart';
import 'package:walk/presentation/diary/page/story_page.dart';
import 'package:walk/presentation/diary/page/trash_page.dart';
import 'package:walk/presentation/diary/viewer/story_viewer_page.dart';
import 'package:walk/presentation/diary/widget/entry_media_view.dart';
import 'package:walk/presentation/diary/widget/feed_view.dart';
import 'package:walk/presentation/diary/widget/story_ring.dart';
import 'package:walk/presentation/diary/widget/story_ring_row.dart';
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

DiaryEntry _entry(
  String body, {
  String storyId = Story.dailyId,
  DateTime? at,
}) => DiaryEntry(
  id: body,
  storyId: storyId,
  body: body,
  occurredAt: at ?? diaryT0,
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

  setUpAll(() {
    registerFallbackValue(const EntryFilter.all());
    registerFallbackValue(<PickedMedia>[]);
  });

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
    navigatorObservers: [appRouteObserver],
    theme: AppTheme.light(),
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider.value(
      value: lock,
      // 셸처럼 바깥 Scaffold 가 ＋ 를 든다.
      child: Scaffold(
        body: DiaryTab(active: active),
        floatingActionButton: const DiaryNewEntryButton(),
      ),
    ),
  );

  Future<void> pump(WidgetTester tester, {bool active = true}) async {
    lock.start();
    await tester.pumpWidget(app(active: active));
    await tester.pumpAndSettle();
  }

  /// 줄의 스토리 동그라미 이름, 왼쪽부터.
  List<String> ringLabels(WidgetTester tester) {
    final rings = tester.widgetList<StoryRing>(find.byType(StoryRing)).toList()
      ..sort(
        (a, b) => tester
            .getTopLeft(find.byWidget(a))
            .dx
            .compareTo(tester.getTopLeft(find.byWidget(b)).dx),
      );
    return [for (final r in rings) r.story.id];
  }

  Finder ring(String title) => find.widgetWithText(StoryRing, title);

  /// 피드 카드 안의 글자(동그라미 줄도 피드 머리로 함께 스크롤해 FeedView 안에 있다).
  Finder inFeed(String text) =>
      find.descendant(of: find.byType(Card), matching: find.text(text));

  Finder appBarMenu() => find.descendant(
    of: find.byType(AppBar),
    matching: find.byIcon(Icons.more_vert),
  );

  /// 뷰어가 열린 뒤 페이드가 끝날 만큼 흘린다(뷰어는 계속 돌아 pumpAndSettle 하지 않는다).
  Future<void> settleViewer(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  StoryViewerPage viewer(WidgetTester tester) =>
      tester.widget<StoryViewerPage>(find.byType(StoryViewerPage));

  testWidgets('잠긴 동안 타임라인 위젯 · ＋ 가 트리에 없고, 풀면 동그라미 줄이 보인다', (tester) async {
    await lockRepo.setSecret(LockMethod.pin, '1234');
    await lockRepo.saveConfig(const LockConfig(enabled: true));
    entries[const EntryFilter.all()] = [_entry('비밀 기록')];
    await pump(tester);

    expect(find.byType(StoryRingRow, skipOffstage: false), findsNothing);
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

    expect(find.byType(StoryRingRow), findsOneWidget);
    expect(find.text('비밀 기록'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  group('다시 잠기면(스펙 §7)', () {
    Future<void> relock(WidgetTester tester) async {
      await lockRepo.setSecret(LockMethod.pin, '1234');
      await lockRepo.saveConfig(const LockConfig(enabled: true));
      final clock = getIt<Clock>() as MutableClock;
      lock.onPaused();
      clock.advance(const Duration(minutes: 5));
      lock.onResumed();
      await tester.pumpAndSettle();
    }

    setUp(() {
      stories = [
        _story(Story.dailyId, ''),
        Story(
          id: 'busan',
          title: '부산 비밀 여행',
          status: StoryStatus.closed,
          startedAt: diaryT0,
          endedAt: diaryT0,
          createdAt: diaryT0,
        ),
      ];
    });

    testWidgets('새 스토리 시트가 닫혀 스토리 이름이 남지 않는다', (tester) async {
      await pump(tester);
      expect(find.text('부산 비밀 여행'), findsOneWidget);
      await tester.tap(find.text('새 스토리'));
      await tester.pumpAndSettle();
      expect(find.byType(StoryFormSheet), findsOneWidget);

      await relock(tester);

      expect(find.byType(BottomSheet, skipOffstage: false), findsNothing);
      expect(find.text('부산 비밀 여행', skipOffstage: false), findsNothing);
      expect(find.byType(PinPad), findsOneWidget);
    });

    testWidgets('가려진 탭이면 다른 탭의 팝업을 닫지 않는다', (tester) async {
      await pump(tester, active: false);
      final context = tester.element(find.byType(DiaryTab));
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(title: Text('알람 다이얼로그')),
        ),
      );
      await tester.pumpAndSettle();

      await relock(tester);

      expect(find.text('알람 다이얼로그'), findsOneWidget);
    });
  });

  testWidgets('앱바 · 동그라미 줄 · 모든 스토리 기록 피드(최신순), 보기 모드 토글 없음', (tester) async {
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
    entries[const EntryFilter.all()] = [
      _entry('바다', storyId: 'jeju', at: diaryT0),
      _entry('출근', at: diaryT0.subtract(const Duration(hours: 1))),
    ];
    await pump(tester);

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('일기')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(appBarMenu(), findsOneWidget);
    expect(ringLabels(tester), ['jeju', Story.dailyId, 'busan']);
    expect(find.text('새 스토리'), findsOneWidget);
    expect(find.text('모두 보기'), findsOneWidget);
    expect(find.byType(FeedView), findsOneWidget);
    expect(
      tester.getTopLeft(inFeed('바다')).dy,
      lessThan(tester.getTopLeft(inFeed('출근')).dy),
    );
    expect(find.text('릴스'), findsNothing);
    // 동그라미 줄이 피드 위에 있다.
    expect(
      tester.getBottomLeft(find.byType(StoryRingRow)).dy,
      lessThanOrEqualTo(tester.getTopLeft(inFeed('바다')).dy),
    );
  });

  testWidgets('기록이 없으면 동그라미 줄 아래 빈 상태 안내', (tester) async {
    await pump(tester);

    expect(find.byType(StoryRingRow), findsOneWidget);
    expect(find.widgetWithText(AppPlaceholder, '아직 기록이 없어요'), findsOneWidget);
  });

  group('뷰어 · 스토리 페이지', () {
    setUp(() {
      final store = _MockStore();
      when(
        () => store.resolve(any()),
      ).thenAnswer((inv) => File('/fake/${inv.positionalArguments.single}'));
      getIt.registerSingleton<MediaStore>(store);
      stories = [
        _story(Story.dailyId, '', lastPostedAt: diaryT0),
        _story(
          'jeju',
          '제주 여행',
          lastPostedAt: diaryT0.subtract(const Duration(days: 1)),
        ),
        _story('busan', '부산 출장'),
      ];
      entries[const EntryFilter.all()] = [
        _entry('출근', at: diaryT0),
        _entry('어제 출근', at: diaryT0.subtract(const Duration(days: 1))),
        _entry(
          '바다',
          storyId: 'jeju',
          at: diaryT0.subtract(const Duration(days: 2)),
        ),
      ];
    });

    testWidgets('동그라미 탭 → 뷰어(그 스토리, 진행 중이면 마지막 날)', (tester) async {
      await pump(tester);
      expect(ringLabels(tester), [Story.dailyId, 'jeju', 'busan']);

      await tester.tap(ring('일상'));
      await settleViewer(tester);

      expect(
        viewer(tester).source,
        const ViewerSource.stories([Story.dailyId, 'jeju', 'busan']),
      );
      expect(viewer(tester).group, 0);
      expect(viewer(tester).entryId, isNull);
      final inViewer = find.byType(StoryViewerPage);
      expect(
        find.descendant(of: inViewer, matching: find.text('출근')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: inViewer, matching: find.text('어제 출근')),
        findsNothing,
      );
    });

    testWidgets('두 번째 동그라미를 누르면 그 순번에서 시작한다', (tester) async {
      await pump(tester);

      await tester.tap(ring('제주 여행'));
      await settleViewer(tester);

      expect(viewer(tester).group, 1);
    });

    testWidgets('기록 없는 스토리 탭 → 스토리 페이지', (tester) async {
      await pump(tester);

      await tester.tap(ring('부산 출장'));
      await tester.pumpAndSettle();

      expect(find.byType(StoryViewerPage), findsNothing);
      expect(tester.widget<StoryPage>(find.byType(StoryPage)).storyId, 'busan');
    });

    testWidgets('동그라미 길게 누르기 → 스토리 페이지', (tester) async {
      await pump(tester);

      await tester.longPress(ring('제주 여행'));
      await tester.pumpAndSettle();

      expect(tester.widget<StoryPage>(find.byType(StoryPage)).storyId, 'jeju');
    });

    testWidgets('모두 보기 → 모든 스토리', (tester) async {
      await pump(tester);

      await tester.tap(find.text('모두 보기'));
      await tester.pumpAndSettle();

      expect(find.byType(AllStoriesPage), findsOneWidget);
    });

    testWidgets('＋ 새 스토리 → 스토리 만들기 시트', (tester) async {
      await pump(tester);

      await tester.tap(find.text('새 스토리'));
      await tester.pumpAndSettle();

      expect(find.byType(StoryFormSheet), findsOneWidget);
    });

    testWidgets('카드 탭 → 뷰어 그 기록', (tester) async {
      await pump(tester);

      await tester.tap(inFeed('어제 출근'));
      await settleViewer(tester);

      expect(
        viewer(tester).source,
        const ViewerSource.stories([Story.dailyId, 'jeju', 'busan']),
      );
      expect(viewer(tester).group, 0);
      expect(viewer(tester).entryId, '어제 출근');
    });

    testWidgets('다른 스토리의 카드 탭 → 그 스토리 순번에서', (tester) async {
      await pump(tester);

      await tester.scrollUntilVisible(
        inFeed('바다'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(inFeed('바다'));
      await settleViewer(tester);

      expect(viewer(tester).group, 1);
      expect(viewer(tester).entryId, '바다');
    });

    testWidgets('카드 머리 탭 → 스토리 페이지', (tester) async {
      await pump(tester);

      await tester.scrollUntilVisible(
        inFeed('바다'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(inFeed('제주 여행'));
      await tester.pumpAndSettle();

      expect(tester.widget<StoryPage>(find.byType(StoryPage)).storyId, 'jeju');
    });

    testWidgets('피드 영상은 자동재생하지 않는다', (tester) async {
      entries[const EntryFilter.all()] = [
        _entry('바다').copyWith(media: [videoMedia('v1')]),
      ];
      await pump(tester);

      expect(
        tester.widget<MediaPager>(find.byType(MediaPager)).playing,
        isFalse,
      );
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    });
  });

  group('작성 화면 열기', () {
    late _MockPicker picker;

    setUp(() {
      picker = _MockPicker();
      when(() => picker.release(any())).thenAnswer((_) async {});
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
        ..registerSingleton<MediaPicker>(picker)
        ..registerSingleton<MediaStore>(store);
    });

    testWidgets('＋ → 시트 4항목, 닫으면 아무 화면도 안 뜸', (tester) async {
      await pump(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final sheet = find.byType(BottomSheet);
      for (final label in ['앨범에서 고르기', '사진 찍기', '영상 찍기', '글만 쓰기']) {
        expect(
          find.descendant(of: sheet, matching: find.text(label)),
          findsOneWidget,
        );
      }

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(EntryEditorPage), findsNothing);
    });

    testWidgets('앨범에서 → 작성 화면이 열리며 고르기가 한 번 실행', (tester) async {
      when(
        () => picker.pickGallery(limit: any(named: 'limit')),
      ).thenAnswer((_) async => const []);
      await pump(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('앨범에서 고르기'));
      await tester.pumpAndSettle();

      verify(() => picker.pickGallery(limit: 10)).called(1);
      // 고르기를 그만둬도 글만 쓰는 작성 화면으로 남는다.
      expect(find.byType(EntryEditorPage), findsOneWidget);
      expect(find.text('새 기록'), findsOneWidget);
    });

    testWidgets('글만 쓰기 → 미디어 없이 작성 화면', (tester) async {
      await pump(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('글만 쓰기'));
      await tester.pumpAndSettle();

      final scope = tester.widget<EntryEditorScope>(
        find.byType(EntryEditorScope),
      );
      expect(scope.editingId, isNull);
      expect(find.byType(EntryEditorPage), findsOneWidget);
      expect(find.text('새 기록'), findsOneWidget);
      verifyNever(() => picker.pickGallery(limit: any(named: 'limit')));
      verifyNever(picker.takePhoto);
      verifyNever(picker.recordVideo);
    });

    testWidgets('앱바 ⋮ → 모든 스토리', (tester) async {
      await pump(tester);

      await tester.tap(appBarMenu());
      await tester.pumpAndSettle();
      await tester.tap(find.text('모든 스토리'));
      await tester.pumpAndSettle();

      expect(find.byType(AllStoriesPage), findsOneWidget);
    });

    testWidgets('앱바 ⋮ → 휴지통', (tester) async {
      when(repo.watchTrash).thenAnswer((_) => Stream.value(const []));
      await pump(tester);

      await tester.tap(appBarMenu());
      await tester.pumpAndSettle();
      await tester.tap(find.text('휴지통'));
      await tester.pumpAndSettle();

      expect(find.byType(TrashPage), findsOneWidget);
    });

    testWidgets('앱바 🔍 → 스토리 결과를 누르면 그 스토리 페이지', (tester) async {
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
      expect(tester.widget<StoryPage>(find.byType(StoryPage)).storyId, 'jeju');
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

  testWidgets('잠긴 동안에는 정리를 부르지 않고, 풀리면 부른다', (tester) async {
    await lockRepo.setSecret(LockMethod.pin, '1234');
    await lockRepo.saveConfig(const LockConfig(enabled: true));
    await pump(tester);
    verifyNever(useCase.maintain);

    // 잠긴 채 탭을 떠났다 돌아와도 부르지 않는다.
    await tester.pumpWidget(app(active: false));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    verifyNever(useCase.maintain);

    await lock.submit('1234');
    await tester.pumpAndSettle();
    verify(useCase.maintain).called(1);
  });

  testWidgets('가려진 탭에서 풀려도 부르지 않고, 탭이 보일 때 부른다', (tester) async {
    await lockRepo.setSecret(LockMethod.pin, '1234');
    await lockRepo.saveConfig(const LockConfig(enabled: true));
    await pump(tester, active: false);

    await lock.submit('1234');
    await tester.pumpAndSettle();
    verifyNever(useCase.maintain);

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
    expect(find.byType(StoryRingRow), findsOneWidget);
  });

  testWidgets('동그라미에 표지 사진을 보인다(R17)', (tester) async {
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

    StoryRing ringOf(String id) => tester.widget<StoryRing>(
      find.byWidgetPredicate((w) => w is StoryRing && w.story.id == id),
    );
    expect(ringOf('jeju').cover?.path, '/fake/media/v1.thumb.jpg');
    expect(ringOf(Story.dailyId).cover, isNull);
  });
}
