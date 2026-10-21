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
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/diary/usecase/diary_use_case.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/presentation/diary/page/story_page.dart';
import 'package:walk/presentation/diary/viewer/story_viewer_page.dart';
import 'package:walk/presentation/diary/widget/entry_grid.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';
import 'package:walk/presentation/lock/widget/pin_pad.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';

class _MockRepo extends Mock implements DiaryRepository {}

class _MockUseCase extends Mock implements DiaryUseCase {}

class _MockStore extends Mock implements MediaStore {}

Story _story(String id, String title, {DateTime? endedAt}) => Story(
  id: id,
  title: title,
  status: endedAt == null ? StoryStatus.open : StoryStatus.closed,
  startedAt: DateTime(2026, 10, 6),
  endedAt: endedAt,
  createdAt: diaryT0,
);

DiaryEntry _entry(
  String id, {
  String storyId = 'jeju',
  DateTime? occurredAt,
  List<EntryMedia> media = const [],
}) => DiaryEntry(
  id: id,
  storyId: storyId,
  body: '글 $id',
  occurredAt: occurredAt ?? diaryT0,
  createdAt: diaryT0,
  updatedAt: diaryT0,
  media: media,
  tags: const [],
);

void main() {
  late _MockRepo repo;
  late _MockUseCase useCase;
  late List<Story> current;
  late Map<EntryFilter, List<DiaryEntry>> entries;
  late List<Story> updated;
  late MutableClock clock;
  late PrefsLockRepository lockRepo;
  late DiaryLockCubit lock;

  setUpAll(() {
    registerFallbackValue(const EntryFilter.all());
    registerFallbackValue(_story('x', 'x'));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    current = [
      _story(Story.dailyId, ''),
      _story('jeju', '제주 여행'),
      _story('busan', '부산', endedAt: DateTime(2026, 10, 8)),
    ];
    entries = {
      const EntryFilter.story('jeju'): [
        _entry(
          'e3',
          occurredAt: DateTime(2026, 10, 8, 9),
          media: [videoMedia('v1')],
        ),
        _entry('e2', occurredAt: DateTime(2026, 10, 7, 9)),
        _entry(
          'e1',
          occurredAt: DateTime(2026, 10, 6, 9),
          media: [photoMedia('p1'), photoMedia('p2')],
        ),
      ],
    };
    updated = [];
    repo = _MockRepo();
    when(repo.watchStories).thenAnswer((_) => Stream.value(current));
    when(() => repo.watchEntries(any())).thenAnswer((inv) {
      final filter = inv.positionalArguments.single as EntryFilter;
      if (filter is AllEntries) {
        return Stream.value([for (final list in entries.values) ...list]);
      }
      return Stream.value(entries[filter] ?? const []);
    });
    when(() => repo.updateStory(any())).thenAnswer((inv) async {
      final story = inv.positionalArguments.single as Story;
      updated.add(story);
      return Ok(story);
    });
    useCase = _MockUseCase();
    when(
      () => useCase.deleteStory(any()),
    ).thenAnswer((_) async => const Ok(null));
    final store = _MockStore();
    when(
      () => store.resolve(any()),
    ).thenAnswer((inv) => File('/fake/${inv.positionalArguments.single}'));
    clock = MutableClock(diaryT0);
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

  tearDown(() async {
    await lock.close();
    await getIt.reset();
  });

  /// 셸처럼 잠금을 내려 주는 첫 화면 위에 스토리 페이지를 띄운다.
  Future<void> open(WidgetTester tester, String storyId) async {
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
                  onPressed: () => openStoryPage(context, storyId),
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

  Finder menu() => find.descendant(
    of: find.byType(AppBar),
    matching: find.byIcon(Icons.more_vert),
  );

  Future<List<String>> menuItems(WidgetTester tester) async {
    await tester.tap(menu());
    await tester.pumpAndSettle();
    return [
      for (final item in tester.widgetList<PopupMenuItem<Object?>>(
        find.byWidgetPredicate((w) => w is PopupMenuItem),
      ))
        tester
            .widgetList<Text>(
              find.descendant(
                of: find.byWidget(item),
                matching: find.byType(Text),
              ),
            )
            .single
            .data!,
    ];
  }

  Future<void> choose(WidgetTester tester, String item) async {
    await tester.tap(menu());
    await tester.pumpAndSettle();
    await tester.tap(find.text(item).last);
    await tester.pumpAndSettle();
  }

  /// 뷰어가 열린 뒤 페이드가 끝날 만큼 흘린다(뷰어는 계속 돌아 pumpAndSettle 하지 않는다).
  Future<void> settleViewer(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('머리 통계 · 처음부터 보기 → 뷰어 fromStart', (tester) async {
    await open(tester, 'jeju');

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('제주 여행')),
      findsOneWidget,
    );
    expect(find.textContaining('10월 6일 ~ 진행 중'), findsOneWidget);
    expect(find.textContaining('기록 3 · 사진 2'), findsOneWidget);
    expect(find.byType(SliverEntryGrid), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, '처음부터 보기'));
    await settleViewer(tester);

    final viewer = tester.widget<StoryViewerPage>(find.byType(StoryViewerPage));
    expect(viewer.source, const ViewerSource.stories(['jeju']));
    expect(viewer.fromStart, isTrue);
    expect(viewer.entryId, isNull);
  });

  testWidgets('칸 탭 → 뷰어 그 기록', (tester) async {
    await open(tester, 'jeju');

    await tester.tap(find.byKey(const ValueKey('grid-e1')));
    await settleViewer(tester);

    final viewer = tester.widget<StoryViewerPage>(find.byType(StoryViewerPage));
    expect(viewer.source, const ViewerSource.stories(['jeju']));
    expect(viewer.entryId, 'e1');
    expect(viewer.fromStart, isFalse);
  });

  testWidgets('기록이 없는 스토리는 안내만, 처음부터 보기가 없다', (tester) async {
    await open(tester, 'busan');

    expect(find.text('아직 기록이 없어요'), findsOneWidget);
    expect(find.widgetWithText(AppButton, '처음부터 보기'), findsNothing);
    expect(find.textContaining('기록 0 · 사진 0'), findsOneWidget);
  });

  testWidgets('기록을 받기 전에는 기록 · 사진 수를 보이지 않는다', (tester) async {
    when(
      () => repo.watchEntries(any()),
    ).thenAnswer((_) => StreamController<List<DiaryEntry>>().stream);
    await open(tester, 'jeju');

    expect(find.textContaining('10월 6일 ~ 진행 중'), findsOneWidget);
    expect(find.textContaining('기록 0'), findsNothing);
    expect(find.textContaining('사진 0'), findsNothing);
  });

  testWidgets('일상은 닫기 · 삭제 없음', (tester) async {
    await open(tester, Story.dailyId);

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('일상')),
      findsOneWidget,
    );
    expect(await menuItems(tester), ['이름 바꾸기', '표지 바꾸기']);
  });

  testWidgets('열린 스토리는 닫기 · 삭제, 닫힌 스토리는 다시 열기', (tester) async {
    await open(tester, 'jeju');
    expect(await menuItems(tester), ['이름 바꾸기', '표지 바꾸기', '닫기', '삭제']);
  });

  testWidgets('닫힌 스토리 메뉴는 다시 열기 · 삭제', (tester) async {
    await open(tester, 'busan');
    expect(await menuItems(tester), ['이름 바꾸기', '표지 바꾸기', '다시 열기', '삭제']);
  });

  testWidgets('⋮ 이름 바꾸기', (tester) async {
    await open(tester, 'jeju');

    await choose(tester, '이름 바꾸기');
    await tester.enterText(find.byType(TextField), '제주 한 달');
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, '저장'));
    await tester.pumpAndSettle();

    expect(updated.single.title, '제주 한 달');
  });

  testWidgets('⋮ 닫기 → 지금 닫기는 지금 시각으로 닫는다', (tester) async {
    await open(tester, 'jeju');

    await choose(tester, '닫기');
    await tester.tap(find.text('지금 닫기'));
    await tester.pumpAndSettle();

    expect(updated.single.id, 'jeju');
    expect(updated.single.isOpen, isFalse);
    expect(updated.single.endedAt, diaryT0);
  });

  testWidgets('⋮ 다시 열기', (tester) async {
    await open(tester, 'busan');

    await choose(tester, '다시 열기');

    expect(updated.single.id, 'busan');
    expect(updated.single.isOpen, isTrue);
  });

  testWidgets('⋮ 삭제는 확인을 받고, 확인하면 지우고 페이지를 닫는다', (tester) async {
    await open(tester, 'jeju');

    await choose(tester, '삭제');
    expect(find.text("'제주 여행' 스토리를 삭제할까요?"), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await tester.pumpAndSettle();
    verifyNever(() => useCase.deleteStory(any()));
    expect(find.byType(StoryPage), findsOneWidget);

    await choose(tester, '삭제');
    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pumpAndSettle();
    verify(() => useCase.deleteStory('jeju')).called(1);
    expect(find.byType(StoryPage), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('동작이 규칙에 걸리면 스낵바로 알리고 페이지는 남는다', (tester) async {
    when(() => useCase.deleteStory(any())).thenAnswer(
      (_) async => const Err(Failure.validation(field: 'defaultStoryLocked')),
    );
    await open(tester, 'jeju');

    await choose(tester, '삭제');
    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(SnackBar, '기본 스토리는 닫거나 지울 수 없어요'),
      findsOneWidget,
    );
    expect(find.byType(StoryPage), findsOneWidget);
  });

  testWidgets('표지 시트에는 그 스토리의 사진만 있고, 고르면 표지가 된다', (tester) async {
    entries[const EntryFilter.story('daily-x')] = [
      _entry('d1', storyId: 'daily-x', media: [photoMedia('daily-photo')]),
    ];
    await open(tester, 'jeju');

    await choose(tester, '표지 바꾸기');

    expect(find.byKey(const ValueKey('cover-p1')), findsOneWidget);
    expect(find.byKey(const ValueKey('cover-daily-photo')), findsNothing);
    expect(find.text('자동 (가장 최근 사진)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cover-p1')));
    await tester.pumpAndSettle();

    expect(updated.single.coverMediaId, 'p1');
  });

  testWidgets('사진이 없는 스토리의 표지 시트는 안내만', (tester) async {
    await open(tester, 'busan');

    await choose(tester, '표지 바꾸기');

    expect(find.text('이 스토리에는 아직 사진이 없어요'), findsOneWidget);
  });

  group('다시 잠기면(스펙 §7)', () {
    Future<void> relock(WidgetTester tester) async {
      await lockRepo.setSecret(LockMethod.pin, '1234');
      await lockRepo.saveConfig(const LockConfig(enabled: true));
      lock.onPaused();
      clock.advance(const Duration(minutes: 5));
      lock.onResumed();
      await tester.pumpAndSettle();
    }

    testWidgets('표지 시트의 사진이 남지 않는다', (tester) async {
      await open(tester, 'jeju');
      await choose(tester, '표지 바꾸기');
      expect(find.byKey(const ValueKey('cover-p1')), findsOneWidget);

      await relock(tester);

      expect(find.byType(BottomSheet, skipOffstage: false), findsNothing);
      expect(find.byType(Image, skipOffstage: false), findsNothing);
      expect(find.byType(PinPad), findsOneWidget);
      expect(find.text('home', skipOffstage: false), findsOneWidget);
    });

    testWidgets('삭제 확인 다이얼로그가 닫히고 지우지 않는다', (tester) async {
      await open(tester, 'jeju');
      await choose(tester, '삭제');
      expect(find.text("'제주 여행' 스토리를 삭제할까요?"), findsOneWidget);

      await relock(tester);

      expect(
        find.text("'제주 여행' 스토리를 삭제할까요?", skipOffstage: false),
        findsNothing,
      );
      expect(find.byType(PinPad), findsOneWidget);
      verifyNever(() => useCase.deleteStory(any()));
    });
  });
}
