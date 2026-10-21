import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';
import 'package:walk/presentation/lock/widget/pin_pad.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/diary_failure.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_draft.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/entity/named_count.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/location/place_lookup.dart';
import 'package:walk/domain/diary/location/place_source.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/diary/usecase/diary_use_case.dart';
import 'package:walk/presentation/diary/media_picker.dart';
import 'package:walk/presentation/diary/page/entry_editor_page.dart';
import 'package:walk/presentation/diary/widget/media_source_sheet.dart';
import 'package:walk/presentation/diary/widget/story_ring.dart';
import 'package:walk/presentation/diary/widget/story_ring_row.dart';
import 'package:walk/presentation/diary/widget/time_row.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';

class _MockRepo extends Mock implements DiaryRepository {}

class _MockUseCase extends Mock implements DiaryUseCase {}

class _MockStore extends Mock implements MediaStore {}

class _MockPicker extends Mock implements MediaPicker {}

class _FakePlaces implements PlaceSource {
  EntryLocation? location;

  @override
  Future<EntryLocation?> current() async => location;

  @override
  Future<PlaceLookup> nameFor(double lat, double lng) async =>
      const PlaceLookup.offline();
}

Story _story(String id, String title, {bool closed = false}) => Story(
  id: id,
  title: title,
  status: closed ? StoryStatus.closed : StoryStatus.open,
  startedAt: DateTime(2026, 10, 1),
  endedAt: closed ? DateTime(2026, 10, 3) : null,
  createdAt: DateTime(2026, 10, 1),
);

const _aewol = EntryLocation(placeName: '애월읍', lat: 33.46, lng: 126.33);

void main() {
  late _MockRepo repo;
  late _MockUseCase useCase;
  late _MockStore store;
  late _MockPicker picker;
  late _FakePlaces places;
  late List<Story> stories;
  late StreamController<List<Story>> storyUpdates;
  late MutableClock clock;
  late PrefsLockRepository lockRepo;
  late DiaryLockCubit lock;

  setUpAll(() {
    registerFallbackValue(entryDraft());
    registerFallbackValue(<EntryMedia>[]);
    registerFallbackValue(<PickedMedia>[]);
    registerFallbackValue(const EntryFilter.all());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    clock = MutableClock(diaryT0);
    stories = [
      _story(Story.dailyId, ''),
      _story('jeju', '제주 여행'),
      _story('busan', '부산 출장', closed: true),
    ];
    storyUpdates = StreamController<List<Story>>.broadcast();
    repo = _MockRepo();
    when(repo.watchStories).thenAnswer((_) async* {
      yield stories;
      yield* storyUpdates.stream;
    });
    when(
      () => repo.watchEntries(any()),
    ).thenAnswer((_) => Stream.value(const []));
    when(() => repo.watchTagCounts(query: any(named: 'query'))).thenAnswer(
      (_) =>
          Stream.value([NamedCount(name: '제주', count: 2, lastUsedAt: diaryT0)]),
    );
    when(() => repo.watchPlaceCounts(query: any(named: 'query'))).thenAnswer(
      (_) => Stream.value([
        NamedCount(name: '협재 해변', count: 4, lastUsedAt: diaryT0),
      ]),
    );
    useCase = _MockUseCase();
    when(() => useCase.cancelDraft(any())).thenAnswer((_) async {});
    store = _MockStore();
    when(() => store.resolve(any())).thenAnswer((_) => File('/missing'));
    picker = _MockPicker();
    when(() => picker.release(any())).thenAnswer((_) async {});
    places = _FakePlaces()..location = _aewol;
    getIt
      ..registerSingleton<DiaryRepository>(repo)
      ..registerSingleton<DiaryUseCase>(useCase)
      ..registerSingleton<MediaStore>(store)
      ..registerSingleton<PlaceSource>(places)
      ..registerSingleton<MediaPicker>(picker)
      ..registerSingleton<Clock>(clock);
    lockRepo = PrefsLockRepository(await SharedPreferences.getInstance());
    lock = DiaryLockCubit(lockRepo, FakeDeviceAuth(), clock, MediaPickGuard());
    getIt
      ..registerSingleton<LockRepository>(lockRepo)
      ..registerSingleton<DeviceAuth>(FakeDeviceAuth());
  });

  tearDown(() async {
    await storyUpdates.close();
    await lock.close();
    await getIt.reset();
  });

  Widget app({String? editingId, MediaSource? initialPick}) => MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider.value(
      value: lock,
      child: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => openEntryEditor(
                context,
                editingId: editingId,
                initialPick: initialPick,
              ),
              child: const Text('home'),
            ),
          ),
        ),
      ),
    ),
  );

  /// 첫 화면(셸처럼 일기 잠금을 내려 주는 자리) 위에 작성 화면을 띄운다. 닫히면 'home' 이 보인다.
  Future<void> pump(
    WidgetTester tester, {
    String? editingId,
    MediaSource? initialPick,
  }) async {
    // 미리보기 · 스토리 줄 아래의 시각 · 장소 행까지 한 화면에 들어오게 세로로 길게.
    tester.view
      ..physicalSize = const Size(800, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    lock.start();
    await tester.pumpWidget(
      app(editingId: editingId, initialPick: initialPick),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
  }

  Finder timeRow() => find.byType(TimeRow);

  Future<void> relock(WidgetTester tester) async {
    await lockRepo.setSecret(LockMethod.pin, '1234');
    await lockRepo.saveConfig(const LockConfig(enabled: true));
    lock.onPaused();
    clock.advance(const Duration(minutes: 5));
    lock.onResumed();
    await tester.pumpAndSettle();
  }

  Future<void> unlock(WidgetTester tester) async {
    for (final d in '1234'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, d));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Finder ringOf(String id) =>
      find.byWidgetPredicate((w) => w is StoryRing && w.story.id == id);

  /// '어디에 올릴까요?' 줄에서 체크된 스토리 id.
  List<String> selectedRings(WidgetTester tester) => [
    for (final r in tester.widgetList<StoryRing>(
      find.descendant(
        of: find.byType(StoryRingRow),
        matching: find.byType(StoryRing),
      ),
    ))
      if (r.selected) r.story.id,
  ];

  List<String> ringIds(WidgetTester tester) => [
    for (final r in tester.widgetList<StoryRing>(
      find.descendant(
        of: find.byType(StoryRingRow),
        matching: find.byType(StoryRing),
      ),
    ))
      r.story.id,
  ];

  Ok<DiaryEntry> savedEntry(String storyId) => Ok(
    DiaryEntry(
      id: 'e1',
      storyId: storyId,
      body: '바다',
      occurredAt: diaryT0,
      createdAt: diaryT0,
      updatedAt: diaryT0,
      media: const [],
      tags: const [],
    ),
  );

  String timeText(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(of: timeRow(), matching: find.byType(Text)),
      )
      .map((t) => t.data)
      .join(' | ');

  testWidgets("시각 행은 '지금', 날짜를 바꾸면 날짜 문구 + 되돌리기, 되돌리면 다시 '지금'", (tester) async {
    await pump(tester);

    expect(timeText(tester), contains('지금 · 10월 10일 (토) 오전 9:00'));
    expect(find.text('올린 시각으로 되돌리기'), findsNothing);

    await tester.tap(timeRow());
    await tester.pumpAndSettle();
    await tester.tap(find.text('9'));
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    // 시각 휠 시트 — 그대로 확인.
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(timeText(tester), contains('10월 9일 (금) 오전 9:00'));
    expect(timeText(tester), isNot(contains('지금')));
    expect(find.text('올린 시각으로 되돌리기'), findsOneWidget);
    // 과거 시각 → 지금 위치 대신 장소 직접 입력칸.
    expect(find.text('애월읍'), findsNothing);
    expect(find.widgetWithText(TextField, '장소 이름'), findsOneWidget);

    await tester.tap(find.text('올린 시각으로 되돌리기'));
    await tester.pumpAndSettle();

    expect(timeText(tester), contains('지금 · 10월 10일 (토)'));
    expect(find.text('올린 시각으로 되돌리기'), findsNothing);
  });

  testWidgets('어디에 올릴까요 줄: 제안 스토리 체크, 탭하면 setStory, 새 기록엔 닫힌 스토리 없음', (
    tester,
  ) async {
    when(
      () => useCase.save(any(), editingId: any(named: 'editingId')),
    ).thenAnswer((_) async => savedEntry('jeju'));
    await pump(tester);

    expect(find.text('어디에 올릴까요?'), findsOneWidget);
    expect(ringIds(tester), containsAll([Story.dailyId, 'jeju']));
    expect(ringIds(tester), isNot(contains('busan')));
    expect(selectedRings(tester), [Story.dailyId]);
    // 작성 화면 줄에는 '모두 보기'가 없다.
    expect(find.text('모두 보기'), findsNothing);

    await tester.tap(ringOf('jeju'));
    await tester.pumpAndSettle();

    expect(selectedRings(tester), ['jeju']);

    await tester.enterText(
      find.widgetWithText(TextField, '오늘 있었던 일을 적어 보세요'),
      '바다',
    );
    await tester.tap(find.text('올리기'));
    await tester.pumpAndSettle();

    final draft =
        verify(
              () => useCase.save(captureAny(), editingId: null),
            ).captured.single
            as EntryDraft;
    expect(draft.storyId, 'jeju');
  });

  testWidgets('＋새 → 만들기 시트 → 만든 스토리 선택', (tester) async {
    final created = Story(
      id: 'chuseok',
      title: '추석',
      status: StoryStatus.open,
      startedAt: diaryT0,
      createdAt: diaryT0,
    );
    when(
      () => repo.createStory(
        title: any(named: 'title'),
        startedAt: any(named: 'startedAt'),
        endedAt: any(named: 'endedAt'),
      ),
    ).thenAnswer((_) async {
      stories = [...stories, created];
      storyUpdates.add(stories);
      return Ok(created);
    });
    await pump(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(StoryRingRow),
        matching: find.text('새 스토리'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      ),
      '추석',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, '만들기'));
    await tester.pumpAndSettle();

    verify(
      () => repo.createStory(
        title: '추석',
        startedAt: any(named: 'startedAt'),
        endedAt: null,
      ),
    ).called(1);
    expect(find.byType(EntryEditorPage), findsOneWidget);
    expect(ringIds(tester), contains('chuseok'));
    expect(selectedRings(tester), ['chuseok']);
  });

  testWidgets('＋새 로 끝난 기간의 스토리를 만들면 못 고른다고 알린다', (tester) async {
    final created = Story(
      id: 'past',
      title: '지난 여행',
      status: StoryStatus.closed,
      startedAt: diaryT0.subtract(const Duration(days: 10)),
      endedAt: diaryT0.subtract(const Duration(days: 5)),
      createdAt: diaryT0,
    );
    when(
      () => repo.createStory(
        title: any(named: 'title'),
        startedAt: any(named: 'startedAt'),
        endedAt: any(named: 'endedAt'),
      ),
    ).thenAnswer((_) async {
      stories = [...stories, created];
      storyUpdates.add(stories);
      return Ok(created);
    });
    await pump(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(StoryRingRow),
        matching: find.text('새 스토리'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      ),
      '지난 여행',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, '만들기'));
    await tester.pumpAndSettle();

    expect(find.text('끝난 스토리라 새 기록을 올릴 수 없어요'), findsOneWidget);
    expect(selectedRings(tester), isNot(contains('past')));
  });

  testWidgets('올리면 스낵바 "제주 여행에 올렸어요"', (tester) async {
    when(
      () => useCase.save(any(), editingId: any(named: 'editingId')),
    ).thenAnswer((_) async => savedEntry('jeju'));
    await pump(tester);
    await tester.tap(ringOf('jeju'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '오늘 있었던 일을 적어 보세요'),
      '바다',
    );

    await tester.tap(find.text('올리기'));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.text('제주 여행에 올렸어요'), findsOneWidget);
  });

  testWidgets('기본 스토리로 올리면 스낵바에 일상 이름', (tester) async {
    when(
      () => useCase.save(any(), editingId: any(named: 'editingId')),
    ).thenAnswer((_) async => savedEntry(Story.dailyId));
    await pump(tester);
    await tester.enterText(
      find.widgetWithText(TextField, '오늘 있었던 일을 적어 보세요'),
      '바다',
    );

    await tester.tap(find.text('올리기'));
    await tester.pumpAndSettle();

    expect(find.text('일상에 올렸어요'), findsOneWidget);
  });

  testWidgets('처음 고르기(initialPick)는 한 번만 — 잠겼다 풀려도 다시 열지 않는다', (tester) async {
    when(
      () => picker.pickGallery(limit: any(named: 'limit')),
    ).thenAnswer((_) async => [(path: '/picked/a.jpg', kind: MediaKind.photo)]);
    when(
      () => store.importPhoto('/picked/a.jpg'),
    ).thenAnswer((_) async => Ok(photoMedia('m1', path: 'tmp/m1.jpg')));
    await pump(tester, initialPick: MediaSource.gallery);

    verify(() => picker.pickGallery(limit: 10)).called(1);
    expect(find.byTooltip('빼기'), findsOneWidget);

    await relock(tester);
    await unlock(tester);

    expect(find.byType(EntryEditorPage), findsOneWidget);
    verifyNever(() => picker.pickGallery(limit: any(named: 'limit')));
    expect(find.byTooltip('빼기'), findsOneWidget);
  });

  testWidgets('처음 고르기를 그만두면 글만 쓰는 작성 화면으로 남는다', (tester) async {
    when(picker.takePhoto).thenAnswer((_) async => const []);
    await pump(tester, initialPick: MediaSource.photo);

    verify(picker.takePhoto).called(1);
    expect(find.byType(EntryEditorPage), findsOneWidget);
    expect(find.byTooltip('빼기'), findsNothing);
  });

  testWidgets('태그 칩 추가 · 삭제 · 추천', (tester) async {
    await pump(tester);
    final tagField = find.widgetWithText(TextField, '태그 추가');

    await tester.enterText(tagField, '#Jeju ');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, '#jeju'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(InputChip, '#jeju'),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsNothing);

    await tester.tap(tagField);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ActionChip, '#제주 2'));
    await tester.tap(find.widgetWithText(ActionChip, '#제주 2'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(InputChip, '#제주'), findsOneWidget);
  });

  testWidgets('위치 ✕ 를 누르면 사라지고 장소 직접 입력, 추천을 누르면 그 이름', (tester) async {
    await pump(tester);
    expect(find.text('애월읍'), findsOneWidget);

    await tester.tap(find.byTooltip('위치 빼기'));
    await tester.pumpAndSettle();

    expect(find.text('애월읍'), findsNothing);
    final placeField = find.widgetWithText(TextField, '장소 이름');
    expect(placeField, findsOneWidget);

    await tester.tap(placeField);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, '협재 해변 4'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '협재 해변'), findsOneWidget);
  });

  testWidgets('올리기 → 입력한 기록으로 저장하고 닫힌다', (tester) async {
    when(
      () => useCase.save(any(), editingId: any(named: 'editingId')),
    ).thenAnswer(
      (inv) async => Ok(
        DiaryEntry(
          id: 'e1',
          storyId: Story.dailyId,
          body: '바다',
          occurredAt: diaryT0,
          createdAt: diaryT0,
          updatedAt: diaryT0,
          media: const [],
          tags: const [],
        ),
      ),
    );
    await pump(tester);

    await tester.enterText(
      find.widgetWithText(TextField, '오늘 있었던 일을 적어 보세요'),
      '바다',
    );
    await tester.tap(find.text('올리기'));
    await tester.pumpAndSettle();

    final draft =
        verify(
              () => useCase.save(captureAny(), editingId: null),
            ).captured.single
            as EntryDraft;
    expect(draft.body, '바다');
    expect(draft.location, _aewol);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('칩으로 만들지 않은 태그 글자도 올리기에 넣는다', (tester) async {
    when(
      () => useCase.save(any(), editingId: any(named: 'editingId')),
    ).thenAnswer(
      (inv) async => Ok(
        DiaryEntry(
          id: 'e1',
          storyId: Story.dailyId,
          body: '바다',
          occurredAt: diaryT0,
          createdAt: diaryT0,
          updatedAt: diaryT0,
          media: const [],
          tags: const ['제주'],
        ),
      ),
    );
    await pump(tester);
    await tester.enterText(
      find.widgetWithText(TextField, '오늘 있었던 일을 적어 보세요'),
      '바다',
    );
    await tester.enterText(find.widgetWithText(TextField, '태그 추가'), '#제주');
    await tester.pump();

    await tester.tap(find.text('올리기'));
    await tester.pumpAndSettle();

    final draft =
        verify(
              () => useCase.save(captureAny(), editingId: null),
            ).captured.single
            as EntryDraft;
    expect(draft.tags, ['제주']);
  });

  testWidgets('저장이 규칙에 걸리면 안내하고 화면에 남는다', (tester) async {
    when(
      () => useCase.save(any(), editingId: any(named: 'editingId')),
    ).thenAnswer((_) async => Err(DiaryFailure.emptyEntry.toFailure()));
    await pump(tester);

    await tester.tap(find.text('올리기'));
    await tester.pump();

    expect(find.text('글이나 사진·영상을 넣어 주세요'), findsOneWidget);
    expect(find.text('올리기'), findsOneWidget);
  });

  testWidgets('쓴 내용이 있으면 닫기 전에 묻고, 그만두면 임시 사본을 지운다', (tester) async {
    await pump(tester);
    await tester.enterText(
      find.widgetWithText(TextField, '오늘 있었던 일을 적어 보세요'),
      '쓰다 만 글',
    );

    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('작성을 그만둘까요?'), findsOneWidget);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('쓰다 만 글'), findsOneWidget);

    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('그만두기'));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    verify(() => useCase.cancelDraft(any())).called(1);
  });

  testWidgets('아무것도 안 바꿨으면 묻지 않고 닫는다', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();

    expect(find.text('작성을 그만둘까요?'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('사진·영상 추가 → 앨범에서 고른 것을 남은 칸만큼 가져온다', (tester) async {
    when(
      () => picker.pickGallery(limit: any(named: 'limit')),
    ).thenAnswer((_) async => [(path: '/picked/a.jpg', kind: MediaKind.photo)]);
    when(
      () => store.importPhoto('/picked/a.jpg'),
    ).thenAnswer((_) async => Ok(photoMedia('m1', path: 'tmp/m1.jpg')));
    await pump(tester);

    await tester.tap(find.text('사진·영상 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('앨범에서 고르기'));
    await tester.pumpAndSettle();

    verify(() => picker.pickGallery(limit: 10)).called(1);
    expect(find.byTooltip('빼기'), findsOneWidget);
  });

  group('고른 원본의 캐시 복사본 정리', () {
    const picked = [
      (path: '/cache/a.jpg', kind: MediaKind.photo),
      (path: '/cache/b.jpg', kind: MediaKind.photo),
    ];

    Future<void> pickFromGallery(WidgetTester tester) async {
      when(
        () => picker.pickGallery(limit: any(named: 'limit')),
      ).thenAnswer((_) async => picked);
      await pump(tester);
      await tester.tap(find.text('사진·영상 추가'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('앨범에서 고르기'));
      await tester.pumpAndSettle();
    }

    testWidgets('가져오기에 성공하면 고른 것을 모두 release 한다', (tester) async {
      for (final id in ['a', 'b']) {
        when(
          () => store.importPhoto('/cache/$id.jpg'),
        ).thenAnswer((_) async => Ok(photoMedia(id, path: 'tmp/$id.jpg')));
      }

      await pickFromGallery(tester);

      verifyInOrder([
        () => store.importPhoto('/cache/a.jpg'),
        () => store.importPhoto('/cache/b.jpg'),
        () => picker.release(picked),
      ]);
    });

    testWidgets('처리에 실패해도 고른 것을 모두 release 한다', (tester) async {
      when(
        () => store.importPhoto(any()),
      ).thenAnswer((_) async => Err(DiaryFailure.mediaProcessing.toFailure()));

      await pickFromGallery(tester);

      verify(() => picker.release(picked)).called(1);
    });

    testWidgets('가져오기가 던져도 고른 것을 release 한다', (tester) async {
      when(
        () => store.importPhoto(any()),
      ).thenAnswer((_) => Future.error(const FileSystemException('disk full')));

      await pickFromGallery(tester);

      verify(() => picker.release(picked)).called(1);
    });
  });

  testWidgets('오래된 닫힌 스토리(11번째)의 기록을 고치면 그 링이 줄에 있고 체크된다', (tester) async {
    stories = [
      _story(Story.dailyId, ''),
      // 더 최근에 닫힌 11개 + 가장 오래된 'oldest'.
      for (var i = 0; i < 11; i++)
        Story(
          id: 'closed$i',
          title: '지난 $i',
          status: StoryStatus.closed,
          startedAt: DateTime(2026, 9, 1),
          endedAt: DateTime(2026, 9, 10 + i),
          createdAt: DateTime(2026, 9, 1),
        ),
      Story(
        id: 'oldest',
        title: '아주 옛날',
        status: StoryStatus.closed,
        startedAt: DateTime(2026, 8, 1),
        endedAt: DateTime(2026, 8, 2),
        createdAt: DateTime(2026, 8, 1),
      ),
    ];
    when(() => repo.entry('e1')).thenAnswer(
      (_) async => Ok(
        DiaryEntry(
          id: 'e1',
          storyId: 'oldest',
          body: '옛 글',
          occurredAt: DateTime(2026, 8, 1, 18),
          createdAt: DateTime(2026, 8, 1, 18),
          updatedAt: DateTime(2026, 8, 1, 18),
          media: const [],
          tags: const [],
        ),
      ),
    );
    await pump(tester, editingId: 'e1');

    expect(ringIds(tester), contains('oldest'));
    expect(selectedRings(tester), ['oldest']);
  });

  testWidgets('스토리 목록이 늦게 와도 처음 고른 미디어가 남는다', (tester) async {
    when(repo.watchStories).thenAnswer((_) async* {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      yield stories;
    });
    when(
      () => picker.pickGallery(limit: any(named: 'limit')),
    ).thenAnswer((_) async => [(path: '/picked/a.jpg', kind: MediaKind.photo)]);
    when(
      () => store.importPhoto('/picked/a.jpg'),
    ).thenAnswer((_) async => Ok(photoMedia('m1', path: 'tmp/m1.jpg')));
    await pump(tester, initialPick: MediaSource.gallery);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    verify(() => picker.pickGallery(limit: 10)).called(1);
    expect(find.byTooltip('빼기'), findsOneWidget);
  });

  testWidgets('고치기: 기록 내용을 채우고 저장 버튼', (tester) async {
    when(() => repo.entry('e1')).thenAnswer(
      (_) async => Ok(
        DiaryEntry(
          id: 'e1',
          storyId: 'jeju',
          body: '옛 글',
          occurredAt: DateTime(2026, 10, 8, 18),
          createdAt: DateTime(2026, 10, 8, 18),
          updatedAt: DateTime(2026, 10, 8, 18),
          location: const EntryLocation(placeName: '협재'),
          media: const [],
          tags: const ['바다'],
        ),
      ),
    );
    await pump(tester, editingId: 'e1');

    expect(find.text('기록 고치기'), findsOneWidget);
    expect(find.text('저장'), findsOneWidget);
    expect(find.text('옛 글'), findsOneWidget);
    expect(selectedRings(tester), ['jeju']);
    // 수정은 지난 스토리로도 옮길 수 있어 닫힌 스토리도 줄에 나온다.
    expect(ringIds(tester), contains('busan'));
    expect(find.widgetWithText(TextField, '협재'), findsOneWidget);
    expect(find.widgetWithText(InputChip, '#바다'), findsOneWidget);
    expect(timeText(tester), contains('10월 8일 (목) 오후 6:00'));
    expect(timeText(tester), isNot(contains('지금')));
  });

  testWidgets('초가 있는 시각에 열고 오늘 같은 분을 그대로 확인하면 지금 · 위치 그대로', (tester) async {
    clock.value = DateTime(2026, 10, 10, 9, 0, 37);
    await pump(tester);

    await tester.tap(timeRow());
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(timeText(tester), contains('지금 · 10월 10일 (토) 오전 9:00'));
    expect(find.text('올린 시각으로 되돌리기'), findsNothing);
    expect(find.text('애월읍'), findsOneWidget);
  });

  testWidgets('다시 잠기면 작성 화면이 트리에서 빠지고, 풀면 쓰던 글 그대로 돌아온다', (tester) async {
    await pump(tester);
    await tester.enterText(
      find.widgetWithText(TextField, '오늘 있었던 일을 적어 보세요'),
      '쓰다 만 글',
    );
    await lockRepo.setSecret(LockMethod.pin, '1234');
    await lockRepo.saveConfig(const LockConfig(enabled: true));

    lock.onPaused();
    clock.advance(const Duration(minutes: 5));
    lock.onResumed();
    await tester.pumpAndSettle();

    expect(find.byType(EntryEditorPage, skipOffstage: false), findsNothing);
    expect(find.text('쓰다 만 글', skipOffstage: false), findsNothing);
    expect(find.byType(PinPad), findsOneWidget);

    for (final d in '1234'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, d));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.byType(EntryEditorPage), findsOneWidget);
    expect(find.text('쓰다 만 글'), findsOneWidget);
  });

  testWidgets('잠금 화면에서 뒤로 가기는 무시한다 — 풀면 쓰던 글 그대로', (tester) async {
    await pump(tester);
    await tester.enterText(
      find.widgetWithText(TextField, '오늘 있었던 일을 적어 보세요'),
      '쓰다 만 글',
    );
    await relock(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('home'), findsNothing);
    expect(find.byType(PinPad), findsOneWidget);
    verifyNever(() => useCase.cancelDraft(any()));

    await unlock(tester);
    expect(find.text('쓰다 만 글'), findsOneWidget);
  });

  testWidgets('다시 잠기면 미디어 고르기 시트가 닫힌다', (tester) async {
    await pump(tester);
    await tester.tap(find.text('사진·영상 추가'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);

    await relock(tester);

    expect(find.byType(BottomSheet, skipOffstage: false), findsNothing);
    expect(find.text('앨범에서 고르기', skipOffstage: false), findsNothing);
    expect(find.byType(PinPad), findsOneWidget);
  });

  testWidgets('취소 없이 화면이 사라져도 새로 가져온 임시 사본을 지운다', (tester) async {
    when(
      () => picker.pickGallery(limit: any(named: 'limit')),
    ).thenAnswer((_) async => [(path: '/picked/a.jpg', kind: MediaKind.photo)]);
    final imported = photoMedia('m1', path: 'tmp/m1.jpg');
    when(
      () => store.importPhoto('/picked/a.jpg'),
    ).thenAnswer((_) async => Ok(imported));
    await pump(tester);
    await tester.tap(find.text('사진·영상 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('앨범에서 고르기'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    final discarded =
        verify(() => useCase.cancelDraft(captureAny())).captured.single
            as List<EntryMedia>;
    expect(discarded, [imported]);
  });
}
