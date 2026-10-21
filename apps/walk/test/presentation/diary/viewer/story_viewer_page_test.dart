import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/diary/usecase/diary_use_case.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/presentation/diary/page/story_page.dart';
import 'package:walk/presentation/diary/viewer/story_progress_bar.dart';
import 'package:walk/presentation/diary/viewer/story_viewer_page.dart';
import 'package:walk/presentation/diary/viewer/viewer_slide_view.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';

class _MockRepo extends Mock implements DiaryRepository {}

class _MockUseCase extends Mock implements DiaryUseCase {}

class _MockStore extends Mock implements MediaStore {}

DiaryEntry _entry(
  String id,
  String storyId,
  DateTime at, {
  String body = '',
  List<EntryMedia> media = const [],
  List<String> tags = const [],
  String? place,
}) => DiaryEntry(
  id: id,
  storyId: storyId,
  body: body,
  occurredAt: at,
  createdAt: at,
  updatedAt: at,
  location: place == null ? null : EntryLocation(placeName: place),
  media: media,
  tags: tags,
);

final _stories = [
  Story(
    id: 'jeju',
    title: '제주 여행',
    status: StoryStatus.open,
    startedAt: DateTime(2026, 10, 6, 8),
    createdAt: DateTime(2026, 10, 6, 8),
  ),
  Story(
    id: Story.dailyId,
    title: '',
    status: StoryStatus.open,
    startedAt: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
  ),
  Story(
    id: 'busan',
    title: '부산',
    status: StoryStatus.closed,
    startedAt: DateTime(2026, 9, 20),
    endedAt: DateTime(2026, 9, 21),
    createdAt: DateTime(2026, 9, 20),
  ),
];

/// 제주: 첫날(10/6) j1(사진 둘) · j2(글) / 둘째 날(10/7) j3(사진) · j4(영상).
/// 일상: 10/9 d1. 부산(닫힘): 9/20 b1.
List<DiaryEntry> _seed() => [
  _entry(
    'j1',
    'jeju',
    DateTime(2026, 10, 6, 10),
    body: '도착',
    media: [photoMedia('p1'), photoMedia('p2')],
  ),
  _entry('j2', 'jeju', DateTime(2026, 10, 6, 12), body: '점심 글'),
  _entry(
    'j3',
    'jeju',
    DateTime(2026, 10, 7, 18, 12),
    body: '노을이 예뻤다',
    media: [photoMedia('p3')],
    tags: ['제주'],
    place: '애월읍',
  ),
  _entry(
    'j4',
    'jeju',
    DateTime(2026, 10, 7, 19),
    media: [videoMedia('v1')],
    tags: ['영상'],
  ),
  _entry(
    'd1',
    Story.dailyId,
    DateTime(2026, 10, 9, 9),
    body: '일상 글',
    media: [photoMedia('p8')],
  ),
  _entry(
    'b1',
    'busan',
    DateTime(2026, 9, 20, 9),
    body: '부산 바다',
    media: [photoMedia('p9')],
    tags: ['제주'],
  ),
];

/// 영상 자리의 가짜 — 마지막으로 받은 [ViewerVideo] 와 새로 만들어진(처음부터 재생) 횟수.
class _Videos {
  ViewerVideo? last;
  var starts = 0;

  Widget build(BuildContext context, ViewerVideo video) {
    last = video;
    return _FakeVideo(video.file.path, this);
  }
}

class _FakeVideo extends StatefulWidget {
  const _FakeVideo(this.path, this.videos);

  final String path;
  final _Videos videos;

  @override
  State<_FakeVideo> createState() => _FakeVideoState();
}

class _FakeVideoState extends State<_FakeVideo> {
  @override
  void initState() {
    super.initState();
    widget.videos.starts++;
  }

  @override
  Widget build(BuildContext context) => Text('video ${widget.path}');
}

void main() {
  late _MockRepo repo;
  late _MockUseCase useCase;
  late List<DiaryEntry> entries;
  late StreamController<List<DiaryEntry>> changes;
  late MutableClock clock;
  late PrefsLockRepository lockRepo;
  late DiaryLockCubit lock;
  late _Videos videos;

  bool matches(EntryFilter filter, DiaryEntry e) => switch (filter) {
    AllEntries() => true,
    StoryEntries(:final storyId) => e.storyId == storyId,
    TagEntries(:final name) => e.tags.contains(name),
    PlaceEntries(:final name) => e.location?.placeName == name,
    BodyEntries(:final query) => e.body.contains(query),
  };

  Stream<List<DiaryEntry>> watch(EntryFilter filter) async* {
    List<DiaryEntry> pick(List<DiaryEntry> all) => [
      for (final e in all)
        if (!e.isTrashed && matches(filter, e)) e,
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    yield pick(entries);
    yield* changes.stream.map(pick);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    clock = MutableClock(DateTime(2026, 10, 10, 10));
    entries = _seed();
    changes = StreamController.broadcast();
    videos = _Videos();
    repo = _MockRepo();
    when(repo.watchStories).thenAnswer((_) => Stream.value(_stories));
    when(
      () => repo.watchEntries(any()),
    ).thenAnswer((inv) => watch(inv.positionalArguments.single as EntryFilter));
    useCase = _MockUseCase();
    when(() => useCase.trash(any())).thenAnswer((inv) async {
      final id = inv.positionalArguments.single as String;
      entries = [
        for (final e in entries)
          e.id == id ? e.copyWith(deletedAt: clock.now()) : e,
      ];
      changes.add(entries);
      return const Ok(null);
    });
    final store = _MockStore();
    when(
      () => store.resolve(any()),
    ).thenAnswer((inv) => File('/fake/${inv.positionalArguments.single}'));
    lockRepo = PrefsLockRepository(await SharedPreferences.getInstance());
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

  setUpAll(() => registerFallbackValue(const EntryFilter.all()));

  tearDown(() async {
    await changes.close();
    await lock.close();
    await getIt.reset();
  });

  const storyIds = ['jeju', Story.dailyId, 'busan'];

  /// 바탕 화면에서 뷰어를 열고 페이드가 끝날 만큼만 흘린다(진행은 그동안 조금 간다).
  Future<void> open(
    WidgetTester tester, {
    ViewerSource source = const ViewerSource.stories(storyIds),
    int group = 0,
    String? entryId,
    bool fromStart = false,
  }) async {
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
                  onPressed: () => openStoryViewer(
                    context,
                    source,
                    group: group,
                    entryId: entryId,
                    fromStart: fromStart,
                    videoBuilder: videos.build,
                  ),
                  child: const Text('home'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // 막대 티커가 첫 틱을 받는 프레임.
    await tester.pump();
  }

  /// 지금 재생 중인 조각 — `기록id/미디어id`(글 조각은 `기록id/text`).
  String current(WidgetTester tester) {
    final views = tester
        .widgetList<ViewerSlideView>(find.byType(ViewerSlideView))
        .where((v) => v.active);
    final slide = views.single.slide;
    return '${slide.entry.id}/${slide.media?.id ?? 'text'}';
  }

  /// [d] 만큼 흘린다. 막대는 길이를 '넘어야' 끝나므로 1ms 더 흘리고, 넘어갔으면 새 조각의
  /// 티커가 첫 틱을 받게 한 프레임 더.
  Future<void> wait(WidgetTester tester, Duration d) async {
    await tester.pump(d);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
  }

  /// 닫기(페이드 아웃)가 끝날 만큼 흘린다.
  Future<void> settleClose(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  bool viewerOpen() => find.byType(StoryViewerPage).evaluate().isNotEmpty;

  testWidgets('진행 중 스토리는 마지막 날 첫 조각, 머리에 이름 · n일차 · 날짜', (tester) async {
    await open(tester);

    expect(current(tester), 'j3/p3');
    expect(find.text('제주 여행'), findsOneWidget);
    expect(find.text('2일차 · 10월 7일 (수)'), findsOneWidget);
    final bar = tester.widget<StoryProgressBar>(find.byType(StoryProgressBar));
    expect((bar.count, bar.index), (2, 0));
    expect(find.text('노을이 예뻤다'), findsOneWidget);
    expect(find.textContaining('애월읍'), findsOneWidget);
    expect(find.text('#제주'), findsOneWidget);
  });

  testWidgets('5초 뒤 다음 조각, 그날 끝이면 다음 날, 마지막이면 닫힌다', (tester) async {
    await open(tester, fromStart: true);
    expect(current(tester), 'j1/p1');
    expect(find.text('1일차 · 10월 6일 (화)'), findsOneWidget);

    await wait(tester, const Duration(seconds: 4));
    expect(current(tester), 'j1/p1');
    await wait(tester, const Duration(seconds: 1));
    expect(current(tester), 'j1/p2');
    await wait(tester, const Duration(seconds: 5));
    expect(current(tester), 'j2/text');
    await wait(tester, const Duration(seconds: 6));
    expect(current(tester), 'j3/p3');
    expect(find.text('2일차 · 10월 7일 (수)'), findsOneWidget);
  });

  testWidgets('마지막 스토리의 마지막 조각 뒤면 닫힌다', (tester) async {
    await open(tester, group: 2);
    expect(current(tester), 'b1/p9');

    await wait(tester, const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 500));
    expect(viewerOpen(), isFalse);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('글 조각은 6초, 영상은 onReady 길이 뒤 onEnded 로 넘어간다', (tester) async {
    await open(tester, entryId: 'j2');
    expect(current(tester), 'j2/text');
    expect(find.text('점심 글'), findsOneWidget);

    await wait(tester, const Duration(seconds: 5));
    expect(current(tester), 'j2/text');
    await wait(tester, const Duration(seconds: 1));
    expect(current(tester), 'j3/p3');
    await wait(tester, const Duration(seconds: 5));
    expect(current(tester), 'j4/v1');
    expect(videos.last!.playing, isTrue);

    // 준비하는 동안 막대는 멈춘다.
    await wait(tester, const Duration(seconds: 10));
    expect(current(tester), 'j4/v1');

    videos.last!.onReady(const Duration(seconds: 3));
    await wait(tester, const Duration(seconds: 3));
    expect(current(tester), 'j4/v1');
    videos.last!.onEnded();
    await wait(tester, const Duration(milliseconds: 500));
    // 제주 끝 → 줄 다음 스토리(일상).
    expect(current(tester), 'd1/p8');
  });

  testWidgets('영상 실패면 5초 뒤 넘어간다', (tester) async {
    await open(tester, entryId: 'j4');
    expect(current(tester), 'j4/v1');

    videos.last!.onFailed();
    await tester.pump();
    await wait(tester, const Duration(seconds: 4));
    expect(current(tester), 'j4/v1');
    await wait(tester, const Duration(seconds: 1));
    await wait(tester, const Duration(milliseconds: 500));
    expect(current(tester), 'd1/p8');
  });

  testWidgets('오른쪽 탭 다음 · 왼쪽 1/3 탭 이전 · 길게 누르면 멈추고 글이 숨는다', (tester) async {
    await open(tester);
    expect(current(tester), 'j3/p3');

    final gesture = await tester.startGesture(const Offset(180, 400));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    expect(find.text('노을이 예뻤다'), findsNothing);
    expect(find.text('제주 여행'), findsNothing);
    await wait(tester, const Duration(seconds: 10));
    expect(current(tester), 'j3/p3');
    await gesture.up();
    await tester.pump();
    expect(find.text('노을이 예뻤다'), findsOneWidget);
    expect(find.text('제주 여행'), findsOneWidget);

    await tester.tapAt(const Offset(300, 400));
    await tester.pump();
    expect(current(tester), 'j4/v1');
    await tester.tapAt(const Offset(40, 400));
    await tester.pump();
    expect(current(tester), 'j3/p3');
    await tester.tapAt(const Offset(40, 400));
    await tester.pump();
    expect(current(tester), 'j2/text');
    expect(find.text('1일차 · 10월 6일 (화)'), findsOneWidget);
  });

  testWidgets('가로로 넘기면 다음 스토리의 시작 위치', (tester) async {
    await open(tester);
    expect(current(tester), 'j3/p3');

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await wait(tester, const Duration(milliseconds: 500));
    expect(current(tester), 'd1/p8');
    expect(find.text('일상'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await wait(tester, const Duration(milliseconds: 500));
    // 지난 스토리는 첫날 첫 조각.
    expect(current(tester), 'b1/p9');

    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await wait(tester, const Duration(milliseconds: 500));
    expect(current(tester), 'd1/p8');
  });

  testWidgets('아래로 끌면 닫힌다', (tester) async {
    await open(tester);

    await tester.drag(find.byType(PageView), const Offset(0, 300));
    await settleClose(tester);
    expect(viewerOpen(), isFalse);
  });

  testWidgets('✕ 를 누르면 닫힌다', (tester) async {
    await open(tester);

    await tester.tap(find.byTooltip('닫기'));
    await settleClose(tester);
    expect(viewerOpen(), isFalse);
  });

  testWidgets('⋮ 휴지통 → 스낵바, 다음 조각으로, 그날이 비면 다음 날', (tester) async {
    await open(tester, fromStart: true);
    expect(current(tester), 'j1/p1');

    Future<void> trashCurrent() async {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('휴지통으로').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    await trashCurrent();
    // 되돌릴 수 있으므로 확인 없이 바로 보낸다.
    expect(find.text('기록을 삭제할까요?'), findsNothing);
    verify(() => useCase.trash('j1')).called(1);
    expect(find.widgetWithText(SnackBar, '기록을 휴지통으로 옮겼어요'), findsOneWidget);
    // 같은 기록의 두 번째 사진은 건너뛴다.
    expect(current(tester), 'j2/text');
    expect(find.text('1일차 · 10월 6일 (화)'), findsOneWidget);

    await trashCurrent();
    verify(() => useCase.trash('j2')).called(1);
    expect(current(tester), 'j3/p3');
    expect(find.text('2일차 · 10월 7일 (수)'), findsOneWidget);
  });

  testWidgets('위에 화면이 얹히면 멈추고 걷히면 같은 조각에서 이어 간다', (tester) async {
    await open(tester);
    expect(current(tester), 'j3/p3');

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('above')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await wait(tester, const Duration(seconds: 10));
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(current(tester), 'j3/p3');

    // 앱이 백그라운드로 가도 멈춘다.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await wait(tester, const Duration(seconds: 10));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(current(tester), 'j3/p3');

    await wait(tester, const Duration(seconds: 5));
    expect(current(tester), 'j4/v1');
  });

  testWidgets('다시 잠겼다 풀리면 같은 조각에서 이어 간다', (tester) async {
    await open(tester);
    await tester.tapAt(const Offset(300, 400));
    await tester.pump();
    expect(current(tester), 'j4/v1');

    await lockRepo.setSecret(LockMethod.pin, '1234');
    await lockRepo.saveConfig(const LockConfig(enabled: true));
    lock.onPaused();
    clock.advance(const Duration(minutes: 5));
    lock.onResumed();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ViewerSlideView), findsNothing);

    for (final d in '1234'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, d));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 500));
    expect(current(tester), 'j4/v1');
  });

  testWidgets('일상은 일차 없이 날짜만', (tester) async {
    await open(tester, group: 1);

    expect(current(tester), 'd1/p8');
    expect(find.text('일상'), findsOneWidget);
    expect(find.text('10월 9일 (금)'), findsOneWidget);
    expect(find.textContaining('일차'), findsNothing);
  });

  testWidgets('모아보기 소스는 #이름 머리, 가로로 넘길 그룹 없음', (tester) async {
    await open(
      tester,
      source: const ViewerSource.filter(EntryFilter.tag('제주'), '#제주'),
      fromStart: true,
    );

    // 태그 제주: b1(9/20) · j3(10/7) — 첫날부터.
    expect(current(tester), 'b1/p9');
    expect(find.text('#제주'), findsWidgets);
    expect(find.text('9월 20일 (일)'), findsOneWidget);
    expect(find.textContaining('일차'), findsNothing);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await wait(tester, const Duration(milliseconds: 500));
    expect(current(tester), 'b1/p9');

    await wait(tester, const Duration(seconds: 5));
    expect(current(tester), 'j3/p3');
    expect(find.text('10월 7일 (수)'), findsOneWidget);
  });
  testWidgets('머리의 스토리 이름을 누르면 그 스토리 페이지가 열리고 뷰어는 멈춘다', (tester) async {
    await open(tester);
    expect(current(tester), 'j3/p3');

    await tester.tap(
      find.descendant(
        of: find.byType(ViewerHeader),
        matching: find.text('제주 여행'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.widget<StoryPage>(find.byType(StoryPage)).storyId, 'jeju');
    // 덮인 동안 넘어가지 않는다 — 돌아오면 같은 조각이다.
    await wait(tester, const Duration(seconds: 10));
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(StoryPage), findsNothing);
    expect(current(tester), 'j3/p3');
  });

  testWidgets('모아보기 머리의 이름은 스토리 페이지를 열지 않는다', (tester) async {
    await open(
      tester,
      source: const ViewerSource.filter(EntryFilter.tag('제주'), '#제주'),
      fromStart: true,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ViewerHeader),
        matching: find.text('#제주'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(StoryPage), findsNothing);
  });

  testWidgets('남은 마지막 조각을 휴지통으로 보내면 닫힌다', (tester) async {
    await open(
      tester,
      source: const ViewerSource.filter(EntryFilter.tag('영상'), '#영상'),
    );
    expect(current(tester), 'j4/v1');

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('휴지통으로').last);
    await settleClose(tester);

    verify(() => useCase.trash('j4')).called(1);
    expect(viewerOpen(), isFalse);
    expect(find.widgetWithText(SnackBar, '기록을 휴지통으로 옮겼어요'), findsOneWidget);
  });

  testWidgets('기록이 모두 사라지면 닫힌다', (tester) async {
    await open(tester);
    expect(current(tester), 'j3/p3');

    entries = [];
    changes.add(entries);
    await settleClose(tester);
    expect(viewerOpen(), isFalse);
  });

  testWidgets('지금 기록의 날이 바뀌면(수정) 그 조각을 새 날에서 다시 찾는다', (tester) async {
    await open(tester);
    expect(current(tester), 'j3/p3');

    entries = [
      for (final e in entries)
        e.id == 'j3' ? e.copyWith(occurredAt: DateTime(2026, 10, 6, 20)) : e,
    ];
    changes.add(entries);
    await tester.pump();

    expect(current(tester), 'j3/p3');
    expect(find.text('1일차 · 10월 6일 (화)'), findsOneWidget);
    final bar = tester.widget<StoryProgressBar>(find.byType(StoryProgressBar));
    expect((bar.count, bar.index), (4, 3));
  });

  testWidgets('처음 읽기에 실패하면 오류 안내와 닫기를 보인다', (tester) async {
    when(
      () => repo.watchEntries(any()),
    ).thenAnswer((_) => Stream.error(StateError('db')));
    await open(tester);

    expect(find.text('기록을 불러오지 못했어요'), findsOneWidget);
    await tester.tap(find.byTooltip('닫기'));
    await settleClose(tester);
    expect(viewerOpen(), isFalse);
  });

  testWidgets('영상 길이가 0 이면 실패처럼 5초 뒤 넘어간다', (tester) async {
    await open(tester, entryId: 'j4');

    videos.last!.onReady(Duration.zero);
    await tester.pump();
    await wait(tester, const Duration(seconds: 4));
    expect(current(tester), 'j4/v1');
    await wait(tester, const Duration(seconds: 1));
    await wait(tester, const Duration(milliseconds: 500));
    expect(current(tester), 'd1/p8');
  });

  testWidgets('맨 처음 영상 조각에서 이전을 누르면 영상을 처음부터 다시 튼다', (tester) async {
    await open(
      tester,
      source: const ViewerSource.filter(EntryFilter.tag('영상'), '#영상'),
    );
    expect(current(tester), 'j4/v1');
    expect(videos.starts, 1);
    videos.last!.onReady(const Duration(seconds: 10));
    await tester.pump();
    await wait(tester, const Duration(seconds: 2));

    await tester.tapAt(const Offset(40, 400));
    await tester.pump();

    expect(current(tester), 'j4/v1');
    expect(videos.starts, 2);
    final bar = tester.widget<StoryProgressBar>(find.byType(StoryProgressBar));
    expect(bar.progress.value, 0);
    // 다시 준비될 때까지 막대는 멈춘다.
    await wait(tester, const Duration(seconds: 3));
    expect(bar.progress.value, 0);
  });

  testWidgets('길게 누르기가 취소되면 다시 간다', (tester) async {
    await open(tester);

    final gesture = await tester.startGesture(const Offset(180, 400));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    expect(find.text('제주 여행'), findsNothing);
    await gesture.cancel();
    await tester.pump();

    expect(find.text('제주 여행'), findsOneWidget);
    await wait(tester, const Duration(seconds: 5));
    expect(current(tester), 'j4/v1');
  });
}
