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
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/location/place_source.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/diary/usecase/diary_use_case.dart';
import 'package:walk/presentation/diary/media_picker.dart';
import 'package:walk/presentation/diary/page/entry_actions.dart';
import 'package:walk/presentation/diary/page/entry_editor_page.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';

class _MockRepo extends Mock implements DiaryRepository {}

class _MockUseCase extends Mock implements DiaryUseCase {}

class _MockStore extends Mock implements MediaStore {}

class _MockPlaces extends Mock implements PlaceSource {}

class _MockPicker extends Mock implements MediaPicker {}

Story _story(String id, String title, {bool open = true}) => Story(
  id: id,
  title: title,
  status: open ? StoryStatus.open : StoryStatus.closed,
  startedAt: diaryT0,
  endedAt: open ? null : diaryT0,
  createdAt: diaryT0,
);

void main() {
  late _MockRepo repo;
  late _MockUseCase useCase;
  late DiaryLockCubit lock;
  late DiaryEntry entry;
  late List<Object?> results;

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
      media: const [],
      tags: const [],
    );
    results = [];
    repo = _MockRepo();
    when(() => repo.entry('e1')).thenAnswer((_) async => Ok(entry));
    when(repo.watchStories).thenAnswer(
      (_) => Stream.value([
        _story('jeju', '제주 여행'),
        _story(Story.dailyId, ''),
        _story('busan', '부산', open: false),
      ]),
    );
    when(
      () => repo.watchTagCounts(query: any(named: 'query')),
    ).thenAnswer((_) => Stream.value(const []));
    when(
      () => repo.watchPlaceCounts(query: any(named: 'query')),
    ).thenAnswer((_) => Stream.value(const []));
    when(
      () => repo.moveEntries(any(), any()),
    ).thenAnswer((_) async => const Ok(null));
    useCase = _MockUseCase();
    when(() => useCase.trash('e1')).thenAnswer((_) async => const Ok(null));
    when(() => useCase.restore('e1')).thenAnswer((_) async => Ok(entry));
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

  /// 버튼 셋(수정 · 옮기기 · 휴지통)이 있는 바탕. 결과는 [results] 에 쌓는다.
  Future<void> pumpHost(WidgetTester tester) async {
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
              body: Column(
                children: [
                  TextButton(
                    onPressed: () async {
                      await editEntry(context, entry);
                      results.add('edited');
                    },
                    child: const Text('edit'),
                  ),
                  TextButton(
                    onPressed: () async =>
                        results.add(await moveEntry(context, entry)),
                    child: const Text('move'),
                  ),
                  TextButton(
                    onPressed: () async =>
                        results.add(await trashEntry(context, entry)),
                    child: const Text('trash'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('trashEntry', () {
    testWidgets('확인하면 휴지통으로 보내고 되돌리기 스낵바를 띄운다', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.text('trash'));
      await tester.pumpAndSettle();
      expect(find.text('기록을 삭제할까요?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '삭제'));
      await tester.pumpAndSettle();

      verify(() => useCase.trash('e1')).called(1);
      expect(results, [true]);
      expect(
        find.widgetWithText(SnackBar, '기록을 휴지통으로 옮겼어요'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(SnackBarAction, '되돌리기'));
      await tester.pumpAndSettle();
      verify(() => useCase.restore('e1')).called(1);
    });

    testWidgets('실패하면 오류를 알리고 false', (tester) async {
      when(
        () => useCase.trash(any()),
      ).thenAnswer((_) async => const Err(Failure.unknown()));
      await pumpHost(tester);
      await tester.tap(find.text('trash'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '삭제'));
      await tester.pumpAndSettle();

      expect(results, [false]);
      expect(
        find.widgetWithText(SnackBar, '휴지통으로 옮기지 못했어요. 다시 시도해 주세요'),
        findsOneWidget,
      );
    });

    testWidgets('확인에서 취소하면 보내지 않고 false', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.text('trash'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pumpAndSettle();

      verifyNever(() => useCase.trash(any()));
      expect(results, [false]);
    });
  });

  group('moveEntry', () {
    testWidgets('스토리를 고르면 옮기고 스낵바로 알린다 — 되돌리면 원래 스토리로', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.text('move'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('일상'), findsOneWidget);
      expect(find.text('부산'), findsOneWidget);
      await tester.tap(find.text('부산'));
      await tester.pumpAndSettle();

      verify(() => repo.moveEntries(['e1'], 'busan')).called(1);
      expect(results, [true]);
      expect(find.widgetWithText(SnackBar, '부산 스토리로 옮겼어요'), findsOneWidget);

      await tester.tap(find.widgetWithText(SnackBarAction, '되돌리기'));
      await tester.pumpAndSettle();
      verify(() => repo.moveEntries(['e1'], 'jeju')).called(1);
    });

    testWidgets('같은 스토리를 고르거나 닫으면 아무것도 하지 않는다', (tester) async {
      await pumpHost(tester);
      await tester.tap(find.text('move'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('제주 여행'));
      await tester.pumpAndSettle();

      verifyNever(() => repo.moveEntries(any(), any()));
      expect(results, [false]);
    });

    testWidgets('옮기지 못하면 오류를 알린다', (tester) async {
      when(
        () => repo.moveEntries(any(), any()),
      ).thenAnswer((_) async => const Err(Failure.unknown()));
      await pumpHost(tester);
      await tester.tap(find.text('move'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('일상'));
      await tester.pumpAndSettle();

      expect(results, [false]);
      expect(
        find.widgetWithText(SnackBar, '옮기지 못했어요. 다시 시도해 주세요'),
        findsOneWidget,
      );
    });
  });

  testWidgets('editEntry 는 그 기록 고치기 화면을 열고 닫히면 끝난다', (tester) async {
    await pumpHost(tester);
    await tester.tap(find.text('edit'));
    await tester.pumpAndSettle();

    final scope = tester.widget<EntryEditorScope>(
      find.byType(EntryEditorScope),
    );
    expect(scope.editingId, 'e1');
    expect(results, isEmpty);

    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(results, ['edited']);
  });
}
