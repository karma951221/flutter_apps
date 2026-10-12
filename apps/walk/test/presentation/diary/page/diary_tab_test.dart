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
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/repository/diary_preferences.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/diary/usecase/diary_use_case.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/presentation/diary/page/diary_tab.dart';
import 'package:walk/presentation/diary/widget/story_avatar.dart';
import 'package:walk/presentation/diary/widget/story_bar.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';
import 'package:walk/presentation/lock/widget/pin_pad.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';

class _MockRepo extends Mock implements DiaryRepository {}

class _MockUseCase extends Mock implements DiaryUseCase {}

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
}
