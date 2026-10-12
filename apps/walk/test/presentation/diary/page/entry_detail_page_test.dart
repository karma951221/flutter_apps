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
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/location/place_source.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/diary/usecase/diary_use_case.dart';
import 'package:walk/presentation/diary/media_picker.dart';
import 'package:walk/presentation/diary/page/entry_detail_page.dart';
import 'package:walk/presentation/diary/page/entry_editor_page.dart';
import 'package:walk/presentation/diary/widget/entry_media_view.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';

class _MockRepo extends Mock implements DiaryRepository {}

class _MockUseCase extends Mock implements DiaryUseCase {}

class _MockStore extends Mock implements MediaStore {}

class _MockPlaces extends Mock implements PlaceSource {}

class _MockPicker extends Mock implements MediaPicker {}

void main() {
  late _MockRepo repo;
  late _MockUseCase useCase;
  late DiaryLockCubit lock;
  late DiaryEntry entry;
  late bool trashed;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final clock = MutableClock(diaryT0.add(const Duration(hours: 1)));
    entry = DiaryEntry(
      id: 'e1',
      storyId: 'jeju',
      body: '바다가 예뻤다',
      occurredAt: diaryT0,
      createdAt: diaryT0,
      updatedAt: diaryT0,
      location: const EntryLocation(placeName: '애월읍'),
      media: [photoMedia('p1')],
      tags: const ['jeju'],
    );
    trashed = false;
    repo = _MockRepo();
    when(() => repo.entry('e1')).thenAnswer(
      (_) async => Ok(trashed ? entry.copyWith(deletedAt: diaryT0) : entry),
    );
    when(repo.watchStories).thenAnswer(
      (_) => Stream.value([
        Story(
          id: 'jeju',
          title: '제주 여행',
          status: StoryStatus.open,
          startedAt: diaryT0,
          createdAt: diaryT0,
        ),
      ]),
    );
    when(
      () => repo.watchTagCounts(query: any(named: 'query')),
    ).thenAnswer((_) => Stream.value(const []));
    when(
      () => repo.watchPlaceCounts(query: any(named: 'query')),
    ).thenAnswer((_) => Stream.value(const []));
    useCase = _MockUseCase();
    when(() => useCase.trash('e1')).thenAnswer((_) async {
      trashed = true;
      return const Ok(null);
    });
    when(() => useCase.cancelDraft(any())).thenAnswer((_) async {});
    final store = _MockStore();
    when(
      () => store.resolve(any()),
    ).thenAnswer((inv) => File('/fake/${inv.positionalArguments.single}'));
    final places = _MockPlaces();
    when(places.current).thenAnswer((_) async => null);
    getIt
      ..registerSingleton<DiaryRepository>(repo)
      ..registerSingleton<DiaryUseCase>(useCase)
      ..registerSingleton<MediaStore>(store)
      ..registerSingleton<PlaceSource>(places)
      ..registerSingleton<MediaPicker>(_MockPicker())
      ..registerSingleton<Clock>(clock);
    lock = DiaryLockCubit(
      PrefsLockRepository(prefs),
      FakeDeviceAuth(),
      clock,
      MediaPickGuard(),
    )..start();
  });

  tearDown(() async {
    await lock.close();
    await getIt.reset();
  });

  Future<void> pumpDetail(WidgetTester tester) async {
    // 폰 세로 화면(360x800) — 정사각 미디어 아래 글이 보인다.
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
        home: BlocProvider.value(
          value: lock,
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => openEntryDetail(context, entry.id),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester, String item) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item).last);
    await tester.pumpAndSettle();
  }

  testWidgets('글 · 날짜 · 장소 · 태그 · 미디어 · 스토리 이름을 보인다', (tester) async {
    await pumpDetail(tester);

    expect(find.byType(EntryDetailPage), findsOneWidget);
    expect(find.text('바다가 예뻤다'), findsOneWidget);
    expect(find.textContaining('10월 10일 (토)'), findsOneWidget);
    expect(find.textContaining('애월읍'), findsOneWidget);
    expect(find.text('#jeju'), findsOneWidget);
    expect(find.byType(MediaPager), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('제주 여행')),
      findsOneWidget,
    );
  });

  testWidgets('⋮ 삭제 → 확인하면 휴지통으로 보내고 닫으며 스낵바로 알린다', (tester) async {
    await pumpDetail(tester);

    await openMenu(tester, '삭제');
    expect(find.text('기록을 삭제할까요?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pumpAndSettle();

    verify(() => useCase.trash('e1')).called(1);
    expect(find.byType(EntryDetailPage), findsNothing);
    expect(find.widgetWithText(SnackBar, '기록을 휴지통으로 옮겼어요'), findsOneWidget);
  });

  testWidgets('삭제 확인에서 취소하면 그대로다', (tester) async {
    await pumpDetail(tester);

    await openMenu(tester, '삭제');
    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await tester.pumpAndSettle();

    verifyNever(() => useCase.trash(any()));
    expect(find.byType(EntryDetailPage), findsOneWidget);
  });

  testWidgets('⋮ 수정은 그 기록 고치기 화면을 열고, 닫으면 새 내용을 다시 읽는다', (tester) async {
    await pumpDetail(tester);

    await openMenu(tester, '수정');

    final scope = tester.widget<EntryEditorScope>(
      find.byType(EntryEditorScope),
    );
    expect(scope.editingId, entry.id);

    entry = entry.copyWith(body: '고친 글');
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();

    expect(find.byType(EntryDetailPage), findsOneWidget);
    expect(find.text('고친 글'), findsOneWidget);
  });

  testWidgets('휴지통에 있는 기록이면 없다고 안내한다', (tester) async {
    trashed = true;
    await pumpDetail(tester);

    expect(find.byType(AppPlaceholder), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });
}
