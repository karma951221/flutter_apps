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
import 'package:walk/data/diary/prefs_diary_preferences.dart';
import 'package:walk/domain/chat/chat_settings.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/diary/diary_failure.dart';
import 'package:walk/domain/diary/draft/draft_context.dart';
import 'package:walk/domain/diary/draft/draft_prompt.dart';
import 'package:walk/domain/diary/draft/draft_style.dart';
import 'package:walk/domain/diary/draft/draft_writer.dart';
import 'package:walk/domain/diary/draft/photo_meta.dart';
import 'package:walk/domain/diary/media/photo_meta_reader.dart';
import 'package:walk/domain/diary/repository/diary_preferences.dart';
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
import 'package:walk/presentation/diary/widget/composer_media_strip.dart';
import 'package:walk/presentation/diary/widget/composer_toolbar.dart';
import 'package:walk/presentation/diary/widget/place_input.dart';
import 'package:walk/presentation/diary/widget/story_picker_sheet.dart';
import 'package:walk/presentation/diary/widget/tag_chip_input.dart';
import 'package:walk/presentation/diary/widget/time_row.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_chat_settings.dart';
import '../../../support/fake_device_auth.dart';

class _MockRepo extends Mock implements DiaryRepository {}

class _MockUseCase extends Mock implements DiaryUseCase {}

class _MockStore extends Mock implements MediaStore {}

class _MockPicker extends Mock implements MediaPicker {}

/// 부를 때마다 새 스트림을 열고 받은 재료를 모은다. 테스트가 [emit] 으로 흘린다.
class _Writer implements DraftWriter {
  final calls = <({DraftContext context, bool includePhotos, bool polish})>[];
  StreamController<DraftEvent>? current;
  var cancelled = 0;
  DraftAvailability available = const DraftAvailability.ready(
    ChatVendor.anthropic,
  );

  @override
  bool canSeePhotos = true;

  @override
  String? get draftModel => 'claude-haiku-5-5';

  @override
  Future<DraftAvailability> availability() async => available;

  @override
  Stream<DraftEvent> write(
    DraftContext context, {
    required DraftStyle style,
    List<EntryMedia> photos = const [],
    bool includePhotos = false,
    bool polish = false,
  }) {
    calls.add((context: context, includePhotos: includePhotos, polish: polish));
    final c = StreamController<DraftEvent>(onCancel: () => cancelled++);
    current = c;
    return c.stream;
  }

  void emit(DraftEvent event) => current!.add(event);
}

class _MetaReader implements PhotoMetaReader {
  final byPath = <String, PhotoMeta>{};

  @override
  Future<PhotoMeta?> read(String path) async => byPath[path];
}

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
  late _Writer writer;
  late FakeChatSettings chatSettings;
  late int openedSettings;
  late _MetaReader metas;

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
    writer = _Writer();
    chatSettings = FakeChatSettings('sk-ant-test')
      ..consentedVendor = ChatVendor.anthropic;
    openedSettings = 0;
    metas = _MetaReader();
    getIt
      ..registerSingleton<DraftWriter>(writer)
      ..registerSingleton<DiaryPreferences>(
        PrefsDiaryPreferences(await SharedPreferences.getInstance()),
      )
      ..registerSingleton<ChatSettings>(chatSettings)
      ..registerSingleton<PhotoMetaReader>(metas);
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

  Widget app({String? editingId}) => MaterialApp(
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
                onOpenChatSettings: () => openedSettings++,
              ),
              child: const Text('home'),
            ),
          ),
        ),
      ),
    ),
  );

  /// 첫 화면(셸처럼 일기 잠금을 내려 주는 자리) 위에 작성 화면을 띄운다. 닫히면 'home' 이 보인다.
  Future<void> pump(WidgetTester tester, {String? editingId}) async {
    // 미리보기 · 스토리 줄 아래의 시각 · 장소 행까지 한 화면에 들어오게 세로로 길게.
    tester.view
      ..physicalSize = const Size(800, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    lock.start();
    await tester.pumpWidget(app(editingId: editingId));
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

  Finder bodyField() => find.widgetWithText(TextField, '오늘 있었던 일을 적어 보세요');

  /// 맨 아래 '스토리' 행.
  Finder storyRow() => find.widgetWithText(AppListTile, '스토리');

  /// 스토리 행에 보이는 지금 스토리 이름.
  String storyRowValue(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(of: storyRow(), matching: find.byType(Text)),
      )
      .map((t) => t.data)
      .where((t) => t != '스토리')
      .join();

  /// 스토리 고르기 시트에 보이는 이름들.
  List<String> sheetTitles(WidgetTester tester) => [
    for (final t in tester.widgetList<Text>(
      find.descendant(
        of: find.byType(StoryPickerSheet),
        matching: find.byType(Text),
      ),
    ))
      ?t.data,
  ];

  Future<void> openStorySheet(WidgetTester tester) async {
    await tester.tap(storyRow());
    await tester.pumpAndSettle();
  }

  Future<void> pickStory(WidgetTester tester, String title) async {
    await openStorySheet(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(StoryPickerSheet),
        matching: find.text(title),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> createFromSheet(WidgetTester tester, String title) async {
    await openStorySheet(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(StoryPickerSheet),
        matching: find.text('새 스토리'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      ),
      title,
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, '만들기'));
    await tester.pumpAndSettle();
  }

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

  testWidgets('글 칸이 맨 위 → 사진 줄 → 태그 · 장소 · 시각 → 스토리 행, 도구줄은 맨 아래', (
    tester,
  ) async {
    await pump(tester);

    double top(Finder f) => tester.getTopLeft(f).dy;
    final order = [
      bodyField(),
      find.byType(TagChipInput),
      find.byType(PlaceInput),
      timeRow(),
      storyRow(),
      find.byType(ComposerToolbar),
    ];
    for (var i = 1; i < order.length; i++) {
      expect(top(order[i - 1]), lessThan(top(order[i])), reason: '$i');
    }
    expect(find.byType(ComposerMediaStrip), findsOneWidget);
    expect(find.text('어디에 올릴까요?'), findsNothing);
  });

  testWidgets('도구줄은 목록과 따로 화면 맨 아래 · 키보드 바로 위에 고정된다', (tester) async {
    await pump(tester);
    final screen = tester.view.physicalSize.height;

    // 목록이 짧아도 도구줄은 화면 맨 아래에 붙는다.
    expect(tester.getBottomLeft(find.byType(ComposerToolbar)).dy, screen);

    // 키보드가 올라오면 도구줄도 키보드 바로 위로 올라오고, 눌린다.
    const keyboard = 1200.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    expect(
      tester.getBottomLeft(find.byType(ComposerToolbar)).dy,
      screen - keyboard,
    );
    expect(
      find
          .descendant(
            of: find.byType(ComposerToolbar),
            matching: find.byTooltip('앨범에서 고르기'),
          )
          .hitTestable(),
      findsOneWidget,
    );
  });

  bool bodyFocused(WidgetTester tester) => tester
      .widget<EditableText>(
        find.descendant(of: bodyField(), matching: find.byType(EditableText)),
      )
      .focusNode
      .hasFocus;

  testWidgets('새 기록은 글 칸에 자동 포커스', (tester) async {
    await pump(tester);

    expect(bodyFocused(tester), isTrue);
  });

  testWidgets('고치기는 자동 포커스하지 않는다', (tester) async {
    when(() => repo.entry('e1')).thenAnswer(
      (_) async => Ok(
        DiaryEntry(
          id: 'e1',
          storyId: Story.dailyId,
          body: '옛 글',
          occurredAt: diaryT0,
          createdAt: diaryT0,
          updatedAt: diaryT0,
          media: const [],
          tags: const [],
        ),
      ),
    );
    await pump(tester, editingId: 'e1');

    expect(bodyFocused(tester), isFalse);
  });

  String bodyText(WidgetTester tester) =>
      tester.widget<TextField>(bodyField()).controller!.text;

  bool bodyReadOnly(WidgetTester tester) =>
      tester.widget<TextField>(bodyField()).readOnly;

  Future<void> addPhoto(WidgetTester tester, {DateTime? takenAt}) async {
    if (takenAt != null) {
      metas.byPath['/picked/a.jpg'] = PhotoMeta(takenAt: takenAt);
    }
    when(
      () => picker.pickGallery(limit: any(named: 'limit')),
    ).thenAnswer((_) async => [(path: '/picked/a.jpg', kind: MediaKind.photo)]);
    when(
      () => store.importPhoto('/picked/a.jpg'),
    ).thenAnswer((_) async => Ok(photoMedia('m1', path: 'tmp/m1.jpg')));
    await tester.tap(find.byTooltip('앨범에서 고르기'));
    await tester.pumpAndSettle();
  }

  Future<void> tapDraft(WidgetTester tester, [String tooltip = '초안 쓰기']) async {
    await tester.pump();
    await tester.tap(find.byTooltip(tooltip));
    await tester.pumpAndSettle();
  }

  group('자동 초안(스펙 2026-11-15 §4)', () {
    testWidgets('✨ 한 번에 글 칸의 글을 메모로 바로 쓰고, 글 칸에 흘려 넣는다', (tester) async {
      await pump(tester);
      await tester.enterText(bodyField(), '카페');

      await tapDraft(tester);

      expect(find.byType(BottomSheet), findsNothing);
      expect(writer.calls.single.context.memo, '카페');
      expect(writer.calls.single.context.placeName, _aewol.placeName);
      expect(writer.calls.single.context.locale, 'ko');
      expect(bodyReadOnly(tester), isTrue);
      expect(find.byTooltip('멈추기'), findsOneWidget);

      writer.emit(const DraftEvent.delta('카페에서 '));
      await tester.pump();
      expect(bodyText(tester), '카페에서 ');
      writer.emit(const DraftEvent.delta('책을 읽었다.'));
      await tester.pump();
      expect(bodyText(tester), '카페에서 책을 읽었다.');
    });

    testWidgets('끝나면 되돌리기 스낵바 — 누르면 원래 메모, ✨ 는 다시 쓰기', (tester) async {
      await pump(tester);
      await tester.enterText(bodyField(), '카페');
      await tapDraft(tester);

      writer.emit(const DraftEvent.done('카페에서 책을 읽었다.'));
      await tester.pumpAndSettle();

      expect(bodyText(tester), '카페에서 책을 읽었다.');
      expect(bodyReadOnly(tester), isFalse);
      expect(find.byTooltip('다시 쓰기'), findsOneWidget);
      expect(find.text('되돌리기'), findsOneWidget);

      await tester.tap(find.text('되돌리기'));
      await tester.pumpAndSettle();

      expect(bodyText(tester), '카페');
      expect(find.byTooltip('초안 쓰기'), findsOneWidget);
    });

    testWidgets('올리면 초안 글이 저장된다', (tester) async {
      when(
        () => useCase.save(any(), editingId: any(named: 'editingId')),
      ).thenAnswer((_) async => savedEntry(Story.dailyId));
      await pump(tester);
      await tester.enterText(bodyField(), '카페');
      await tapDraft(tester);
      writer.emit(const DraftEvent.done('카페에서 책을 읽었다.'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('올리기'));
      await tester.pumpAndSettle();

      final draft =
          verify(
                () => useCase.save(
                  captureAny(),
                  editingId: any(named: 'editingId'),
                ),
              ).captured.single
              as EntryDraft;
      expect(draft.body, '카페에서 책을 읽었다.');
    });

    testWidgets('실패하면 원래 메모로 되돌리고 이유를 알린다', (tester) async {
      await pump(tester);
      await tester.enterText(bodyField(), '카페');
      await tapDraft(tester);

      writer.emit(const DraftEvent.delta('카페에서'));
      writer.emit(const DraftEvent.failed(ChatFailure.network));
      await tester.pumpAndSettle();

      expect(bodyText(tester), '카페');
      expect(find.text('연결이 끊겼어요. 다시 물어봐 주세요'), findsOneWidget);
      expect(find.byTooltip('초안 쓰기'), findsOneWidget);
    });

    testWidgets('멈추면 그때까지의 글이 남는다', (tester) async {
      await pump(tester);
      await tester.enterText(bodyField(), '카페');
      await tapDraft(tester);
      writer.emit(const DraftEvent.delta('카페에서 책을'));
      await tester.pump();

      await tester.tap(find.byTooltip('멈추기'));
      await tester.pumpAndSettle();

      expect(writer.cancelled, 1);
      expect(bodyText(tester), '카페에서 책을');
      expect(bodyReadOnly(tester), isFalse);
    });

    testWidgets('다시 쓰기: 그대로면 원래 메모로, 고쳤으면 고친 글을 다듬는다', (tester) async {
      await pump(tester);
      await tester.enterText(bodyField(), '카페');
      await tapDraft(tester);
      writer.emit(const DraftEvent.done('카페에서 책을 읽었다.'));
      await tester.pumpAndSettle();

      await tapDraft(tester, '다시 쓰기');
      expect(writer.calls.last.context.memo, '카페');
      expect(writer.calls.last.polish, isFalse);
      writer.emit(const DraftEvent.done('카페에서 독서했다.'));
      await tester.pumpAndSettle();

      await tester.enterText(bodyField(), '카페에서 독서했다. 비가 왔다.');
      await tapDraft(tester, '다시 쓰기');
      expect(writer.calls.last.context.memo, '카페에서 독서했다. 비가 왔다.');
      expect(writer.calls.last.polish, isTrue);
    });

    testWidgets('글 칸이 비고 사진 보여 주기가 꺼져 있으면 ✨ 가 꺼진다', (tester) async {
      await pump(tester);

      final button = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('한 줄 적거나 사진 보여 주기를 켜세요'),
          matching: find.byType(IconButton),
        ),
      );
      expect(button.onPressed, isNull);

      await tester.enterText(bodyField(), '카페');
      await tester.pump();
      expect(find.byTooltip('초안 쓰기'), findsOneWidget);
    });

    testWidgets('사진 보여 주기: 사진이 있을 때만 보이고, 켜는 순간 확인 후 기억한다', (tester) async {
      await pump(tester);
      expect(find.text('사진 보여 주기'), findsNothing);
      await addPhoto(tester);

      await tester.tap(find.text('사진 보여 주기'));
      await tester.pumpAndSettle();
      expect(find.textContaining('사진 1장까지 Claude로 보내져요'), findsOneWidget);
      await tester.tap(find.text('켜기'));
      await tester.pumpAndSettle();

      expect(getIt<DiaryPreferences>().draftIncludePhotos, isTrue);
      // 메모 없이 사진만으로 ✨ 가 켜진다.
      await tapDraft(tester);
      expect(writer.calls.single.includePhotos, isTrue);
      expect(writer.calls.single.context.memo, '');
    });

    testWidgets('확인에서 그만두면 사진 보여 주기는 꺼진 채다', (tester) async {
      await pump(tester);
      await addPhoto(tester);

      await tester.tap(find.text('사진 보여 주기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(getIt<DiaryPreferences>().draftIncludePhotos, isFalse);
    });

    testWidgets('기억된 켬이면 다시 묻지 않고 끌 때도 묻지 않는다', (tester) async {
      await getIt<DiaryPreferences>().setDraftIncludePhotos(true);
      await pump(tester);
      await addPhoto(tester);

      final chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(chip.selected, isTrue);
      await tester.tap(find.text('사진 보여 주기'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(getIt<DiaryPreferences>().draftIncludePhotos, isFalse);
    });

    testWidgets('초안 모델이 사진을 못 보면 토글이 꺼진다', (tester) async {
      writer.canSeePhotos = false;
      await pump(tester);
      await addPhoto(tester);

      expect(
        tester.widget<FilterChip>(find.byType(FilterChip)).onSelected,
        isNull,
      );
      expect(find.byTooltip('이 모델은 사진을 볼 수 없어요'), findsOneWidget);
    });

    testWidgets('키가 없으면 안내 다이얼로그 → 설정 열기', (tester) async {
      writer.available = const DraftAvailability.noKey();
      await pump(tester);
      await tester.enterText(bodyField(), '카페');

      await tapDraft(tester);
      expect(find.text('물어보기 설정에서 키를 넣으면 쓸 수 있어요.'), findsOneWidget);
      await tester.tap(find.text('설정 열기'));
      await tester.pumpAndSettle();

      expect(openedSettings, 1);
      expect(writer.calls, isEmpty);
    });

    testWidgets('첫 사용이면 동의를 받고 기록한 뒤 쓴다', (tester) async {
      writer.available = const DraftAvailability.needsConsent(
        ChatVendor.anthropic,
      );
      chatSettings.consentedVendor = null;
      await pump(tester);
      await tester.enterText(bodyField(), '카페');

      await tapDraft(tester);
      expect(find.text('AI로 보내기'), findsOneWidget);
      expect(
        find.text(
          '초안을 쓸 때 글 칸의 메모와 기록 시각 · 장소 이름 · 태그가 Claude로 전송돼요. '
          '사진은 사진 보여 주기를 켰을 때만 보내요. 키는 이 폰의 보안 저장소에만 있어요.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('걸음'), findsNothing);
      expect(find.textContaining('위키'), findsNothing);
      await tester.tap(find.text('동의하고 시작'));
      await tester.pumpAndSettle();

      expect(chatSettings.consentedVendor, ChatVendor.anthropic);
      expect(writer.calls.single.context.memo, '카페');
    });

    testWidgets('동의하지 않으면 쓰지 않는다', (tester) async {
      writer.available = const DraftAvailability.needsConsent(
        ChatVendor.anthropic,
      );
      await pump(tester);
      await tester.enterText(bodyField(), '카페');

      await tapDraft(tester);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(writer.calls, isEmpty);
    });

    testWidgets('쓰는 중에 다시 잠기면 취소하고, 풀면 그때까지의 글이 남아 있다', (tester) async {
      await pump(tester);
      await tester.enterText(bodyField(), '카페');
      await tapDraft(tester);
      writer.emit(const DraftEvent.delta('카페에서 책을'));
      await tester.pump();

      await relock(tester);
      expect(writer.cancelled, 1);
      await unlock(tester);

      expect(bodyText(tester), '카페에서 책을');
      expect(bodyReadOnly(tester), isFalse);
      expect(find.byTooltip('다시 쓰기'), findsOneWidget);
    });

    testWidgets('어제 찍은 사진: 시각 칩 → 그 시각으로, 자동 위치는 재료에서 빠진다', (tester) async {
      await pump(tester);
      await tester.enterText(bodyField(), '바다');
      await addPhoto(tester, takenAt: DateTime(2026, 10, 9, 15, 20));

      await tapDraft(tester);
      final ctx = writer.calls.single.context;
      expect(ctx.photoTakenFrom, DateTime(2026, 10, 9, 15, 20));
      expect(ctx.autoPlace, isTrue);
      expect(DraftPrompt.user(ctx), isNot(contains('장소:')));
      writer.emit(const DraftEvent.done('바다를 봤다.'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('찍은 시각으로(어제 오후 3:20)'));
      await tester.pumpAndSettle();

      expect(timeText(tester), contains('10월 9일 (금) 오후 3:20'));
      expect(find.textContaining('찍은 시각으로'), findsNothing);
    });
  });

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

  testWidgets('스토리 행: 기본은 일상, 누르면 시트(새 기록엔 닫힌 스토리 없음) → 고른 스토리로 올린다', (
    tester,
  ) async {
    when(
      () => useCase.save(any(), editingId: any(named: 'editingId')),
    ).thenAnswer((_) async => savedEntry('jeju'));
    await pump(tester);

    expect(storyRowValue(tester), '일상');

    await openStorySheet(tester);
    expect(sheetTitles(tester), containsAll(['일상', '제주 여행', '새 스토리']));
    expect(sheetTitles(tester), isNot(contains('부산 출장')));
    await tester.tap(
      find.descendant(
        of: find.byType(StoryPickerSheet),
        matching: find.text('제주 여행'),
      ),
    );
    await tester.pumpAndSettle();

    expect(storyRowValue(tester), '제주 여행');

    await tester.enterText(bodyField(), '바다');
    await tester.tap(find.text('올리기'));
    await tester.pumpAndSettle();

    final draft =
        verify(
              () => useCase.save(captureAny(), editingId: null),
            ).captured.single
            as EntryDraft;
    expect(draft.storyId, 'jeju');
  });

  testWidgets('스토리 시트 ＋새 → 만들기 시트 → 만든 스토리 선택', (tester) async {
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

    await createFromSheet(tester, '추석');

    verify(
      () => repo.createStory(
        title: '추석',
        startedAt: any(named: 'startedAt'),
        endedAt: null,
      ),
    ).called(1);
    expect(find.byType(EntryEditorPage), findsOneWidget);
    expect(storyRowValue(tester), '추석');
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

    await createFromSheet(tester, '지난 여행');

    expect(find.text('끝난 스토리라 새 기록을 올릴 수 없어요'), findsOneWidget);
    expect(storyRowValue(tester), '일상');
  });

  testWidgets("일상이 아닌 스토리에 올리면 스낵바 \"'제주 여행'에 올렸어요\"", (tester) async {
    when(
      () => useCase.save(any(), editingId: any(named: 'editingId')),
    ).thenAnswer((_) async => savedEntry('jeju'));
    await pump(tester);
    await pickStory(tester, '제주 여행');
    await tester.enterText(bodyField(), '바다');

    await tester.tap(find.text('올리기'));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.text("'제주 여행'에 올렸어요"), findsOneWidget);
    expect(find.text('올렸어요'), findsNothing);
  });

  testWidgets('일상에 올리면 스낵바 "올렸어요"(스토리 이름 없이)', (tester) async {
    when(
      () => useCase.save(any(), editingId: any(named: 'editingId')),
    ).thenAnswer((_) async => savedEntry(Story.dailyId));
    await pump(tester);
    await tester.enterText(bodyField(), '바다');

    await tester.tap(find.text('올리기'));
    await tester.pumpAndSettle();

    expect(find.text('올렸어요'), findsOneWidget);
    expect(find.textContaining("'"), findsNothing);
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

    await tester.enterText(bodyField(), '바다');
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
    await tester.enterText(bodyField(), '바다');
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
    await tester.enterText(bodyField(), '쓰다 만 글');

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

  testWidgets('도구줄 앨범 → 남은 칸만큼 가져와 썸네일 줄에, ✕ 로 뺀다', (tester) async {
    when(
      () => picker.pickGallery(limit: any(named: 'limit')),
    ).thenAnswer((_) async => [(path: '/picked/a.jpg', kind: MediaKind.photo)]);
    when(
      () => store.importPhoto('/picked/a.jpg'),
    ).thenAnswer((_) async => Ok(photoMedia('m1', path: 'tmp/m1.jpg')));
    await pump(tester);

    await tester.tap(find.byTooltip('앨범에서 고르기'));
    await tester.pumpAndSettle();

    verify(() => picker.pickGallery(limit: 10)).called(1);
    expect(
      find.descendant(
        of: find.byType(ComposerMediaStrip),
        matching: find.byTooltip('빼기'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('빼기'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('빼기'), findsNothing);
  });

  testWidgets('한도만큼 붙이면 도구줄 고르기 버튼이 꺼진다', (tester) async {
    final picked = [
      for (var i = 0; i < 10; i++)
        (path: '/picked/$i.jpg', kind: MediaKind.photo),
    ];
    when(
      () => picker.pickGallery(limit: any(named: 'limit')),
    ).thenAnswer((_) async => picked);
    for (var i = 0; i < 10; i++) {
      when(
        () => store.importPhoto('/picked/$i.jpg'),
      ).thenAnswer((_) async => Ok(photoMedia('m$i', path: 'tmp/m$i.jpg')));
    }
    await pump(tester);

    await tester.tap(find.byTooltip('앨범에서 고르기'));
    await tester.pumpAndSettle();

    final toolbar = tester.widget<ComposerToolbar>(
      find.byType(ComposerToolbar),
    );
    expect(toolbar.count, 10);
    final gallery = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('앨범에서 고르기'),
        matching: find.byType(IconButton),
      ),
    );
    expect(gallery.onPressed, isNull);
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
      await tester.tap(find.byTooltip('앨범에서 고르기'));
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

  testWidgets('오래된 닫힌 스토리(11번째)의 기록을 고치면 스토리 행 · 시트에 그 스토리', (tester) async {
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

    expect(storyRowValue(tester), '아주 옛날');
    await openStorySheet(tester);
    expect(sheetTitles(tester), contains('아주 옛날'));
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
    expect(storyRowValue(tester), '제주 여행');
    expect(find.widgetWithText(TextField, '협재'), findsOneWidget);
    expect(find.widgetWithText(InputChip, '#바다'), findsOneWidget);
    expect(timeText(tester), contains('10월 8일 (목) 오후 6:00'));
    expect(timeText(tester), isNot(contains('지금')));
    // 수정은 지난 스토리로도 옮길 수 있어 닫힌 스토리도 시트에 나온다.
    await openStorySheet(tester);
    expect(sheetTitles(tester), contains('부산 출장'));
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
    await tester.enterText(bodyField(), '쓰다 만 글');
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
    await tester.enterText(bodyField(), '쓰다 만 글');
    await relock(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('home'), findsNothing);
    expect(find.byType(PinPad), findsOneWidget);
    verifyNever(() => useCase.cancelDraft(any()));

    await unlock(tester);
    expect(find.text('쓰다 만 글'), findsOneWidget);
  });

  testWidgets('다시 잠기면 스토리 고르기 시트가 닫힌다', (tester) async {
    await pump(tester);
    await openStorySheet(tester);
    expect(find.byType(StoryPickerSheet), findsOneWidget);

    await relock(tester);

    expect(find.byType(BottomSheet, skipOffstage: false), findsNothing);
    expect(find.byType(StoryPickerSheet, skipOffstage: false), findsNothing);
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
    await tester.tap(find.byTooltip('앨범에서 고르기'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    final discarded =
        verify(() => useCase.cancelDraft(captureAny())).captured.single
            as List<EntryMedia>;
    expect(discarded, [imported]);
  });
}
