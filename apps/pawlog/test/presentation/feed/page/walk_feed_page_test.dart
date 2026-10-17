import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/domain/backup/entity/backup_import_result.dart';
import 'package:pawlog/domain/tracking/entity/tracker_state.dart';
import 'package:pawlog/domain/walk/entity/geo_point.dart';
import 'package:pawlog/domain/walk/entity/walk.dart';
import 'package:pawlog/domain/walk/entity/walk_photo.dart';
import 'package:pawlog/presentation/dog/widget/dog_avatars.dart';
import 'package:pawlog/presentation/feed/cubit/walk_feed_cubit.dart';
import 'package:pawlog/presentation/feed/page/walk_feed_page.dart';
import 'package:pawlog/presentation/feed/widget/walk_feed_entry.dart';
import 'package:pawlog/presentation/tracking/widget/active_walk_banner.dart';

import '../../../support/fakes.dart';
import '../../../support/mock_walk_use_case.dart';
import '../../../support/pump_app.dart';

Walk _walk(
  String id, {
  String? memo,
  List<WalkPhoto> photos = const [],
  DateTime? startedAt,
}) => Walk(
  id: id,
  startedAt: startedAt ?? t0,
  endedAt: t1,
  duration: const Duration(minutes: 30),
  distanceMeters: 1200,
  memo: memo,
  dogs: [dog('1')],
  photos: photos,
  previewPoints: const [
    GeoPoint(lat: 37.5, lng: 127),
    GeoPoint(lat: 37.51, lng: 127.01),
  ],
  createdAt: t0,
  updatedAt: t0,
);

void main() {
  late MockWalkUseCase useCase;
  late TrackerState current;

  setUp(() {
    useCase = MockWalkUseCase();
    current = const TrackerState.idle();
    when(() => useCase.trackerState).thenAnswer((_) => current);
    when(() => useCase.trackerStates).thenAnswer((_) => const Stream.empty());
    when(
      () => useCase.watchWalks(),
    ).thenAnswer((_) => Stream.value(Ok([_walk('a', memo: '공원 한 바퀴')])));
    when(() => useCase.photoFile(any())).thenReturn(File('missing.png'));
    getIt.registerFactory<WalkFeedCubit>(
      () => WalkFeedCubit(useCase, FakeClock.fixed(DateTime(2026, 10, 3, 12))),
    );
  });
  tearDown(getIt.reset);

  Future<void> pump(
    WidgetTester tester, {
    bool disableAnimations = false,
    VoidCallback? onStartWalk,
    VoidCallback? onSaveWalk,
    ValueChanged<String>? onOpenWalk,
    VoidCallback? onOpenDogs,
    VoidCallback? onOpenStats,
  }) => pumpApp(
    tester,
    WalkFeedPage(
      onStartWalk: onStartWalk ?? () {},
      onSaveWalk: onSaveWalk ?? () {},
      onOpenWalk: onOpenWalk ?? (_) {},
      onOpenDogs: onOpenDogs ?? () {},
      onOpenStats: onOpenStats ?? () {},
    ),
    disableAnimations: disableAnimations,
  );

  testWidgets('빈 피드는 날짜 열 없이 안내 한 줄과 하단 시작 버튼을 보인다', (tester) async {
    when(
      () => useCase.watchWalks(),
    ).thenAnswer((_) => Stream.value(const Ok([])));
    var started = 0;

    await pump(tester, onStartWalk: () => started++);

    expect(find.byType(AppPlaceholder), findsOneWidget);
    expect(find.text('첫 산책을 시작해 보세요'), findsOneWidget);
    expect(find.byType(WalkFeedEntry), findsNothing);
    expect(find.byKey(const Key('walk-feed-start-button')), findsOneWidget);
    await tester.tap(find.text('산책 시작'));
    expect(started, 1);
  });

  for (final (name, tracker) in [
    ('추적 중', TrackerState.tracking(walkSession(distanceMeters: 300))),
    ('저장 안 한 산책이 있을 때', TrackerState.finished(walkSession(endedAt: t1))),
  ]) {
    testWidgets('빈 피드라도 $name 이면 시작 안내 · 버튼 대신 배너로 이끈다', (tester) async {
      when(
        () => useCase.watchWalks(),
      ).thenAnswer((_) => Stream.value(const Ok([])));
      current = tracker;

      // 추적 중 배너의 연두 점은 끝없이 점멸한다.
      await pump(tester, disableAnimations: true);

      expect(find.byKey(const Key('walk-feed-banner')), findsOneWidget);
      expect(find.text('첫 산책을 시작해 보세요'), findsNothing);
      expect(find.text('산책 시작'), findsNothing);
      expect(find.text('첫 산책이 곧 여기에 보여요'), findsOneWidget);
      expect(find.byKey(const Key('walk-feed-start-button')), findsNothing);
    });
  }

  testWidgets('항목에 날짜 열 · 반려견 · 시각 · 거리 · 시간 · 메모가 보인다', (tester) async {
    await pump(tester);

    expect(find.byKey(const Key('walk-feed-entry-a')), findsOneWidget);
    expect(find.byType(Card), findsNothing); // 카드가 아니라 줄글이다
    expect(find.text('2026년 10월'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // 날짜 열의 일
    expect(find.text('토'), findsOneWidget); // 요일
    expect(find.text('콩이1'), findsOneWidget);
    expect(find.byType(DogAvatars), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('1.2 km'), findsOneWidget);
    expect(find.text('30분'), findsOneWidget);
    expect(find.text('공원 한 바퀴'), findsOneWidget);
  });

  testWidgets('같은 날 기록은 날짜를 한 번만 쓰고 리드줄로 잇는다', (tester) async {
    // 세 항목이 한 화면에 다 들어오게 폰 폭 · 긴 화면.
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final evening = t0.add(const Duration(hours: 9));
    final yesterday = t0.subtract(const Duration(days: 1));
    when(() => useCase.watchWalks()).thenAnswer(
      (_) => Stream.value(
        Ok([
          _walk('pm', startedAt: evening),
          _walk('am'),
          _walk('prev', startedAt: yesterday),
        ]),
      ),
    );

    await pump(tester);

    WalkFeedEntry entry(String id) =>
        tester.widget(find.byKey(Key('walk-feed-entry-$id')));
    expect(find.byKey(const Key('walk-feed-date-pm')), findsOneWidget);
    expect(find.byKey(const Key('walk-feed-date-am')), findsNothing);
    expect(entry('pm').showDate, isTrue);
    expect(entry('pm').continuesBelow, isTrue);
    expect(entry('am').showDate, isFalse);
    expect(entry('am').continuesBelow, isFalse);
    expect(find.byKey(const Key('walk-feed-date-prev')), findsOneWidget);
    expect(entry('prev').showDate, isTrue);
    // 같은 달이라 달 머리는 맨 위 하나뿐이다.
    expect(find.byType(WalkFeedMonthHeader), findsOneWidget);
  });

  testWidgets('메모가 없으면 메모 줄이 없다', (tester) async {
    when(
      () => useCase.watchWalks(),
    ).thenAnswer((_) => Stream.value(Ok([_walk('a')])));

    await pump(tester);

    expect(find.text('공원 한 바퀴'), findsNothing);
    expect(find.byKey(const Key('walk-feed-entry-a')), findsOneWidget);
  });

  testWidgets('카드를 탭하면 onOpenWalk(id) 를 부른다', (tester) async {
    String? opened;

    await pump(tester, onOpenWalk: (id) => opened = id);
    await tester.tap(find.byKey(const Key('walk-feed-entry-a')));

    expect(opened, 'a');
  });

  testWidgets('사진이 없으면 경로 썸네일, 있으면 Image 를 쓴다', (tester) async {
    await pump(tester);
    expect(find.byType(Image), findsNothing);

    when(() => useCase.watchWalks()).thenAnswer(
      (_) => Stream.value(
        Ok([
          _walk(
            'a',
            photos: const [WalkPhoto(id: 'p', path: 'p.png', position: 0)],
          ),
        ]),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await pump(tester);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('하단 시작 버튼을 누르면 onStartWalk 를 부른다', (tester) async {
    var started = 0;

    await pump(tester, onStartWalk: () => started++);
    await tester.tap(find.byKey(const Key('walk-feed-start-button')));

    expect(started, 1);
    expect(find.text('산책 시작'), findsOneWidget);
    expect(find.byKey(const Key('walk-feed-banner')), findsNothing);
  });

  testWidgets('추적 중이면 배너와 산책 계속 버튼이 모두 onStartWalk 를 부른다', (tester) async {
    current = TrackerState.tracking(walkSession(distanceMeters: 300));
    var started = 0;

    await pump(tester, disableAnimations: true, onStartWalk: () => started++);

    expect(find.byKey(const Key('walk-feed-banner')), findsOneWidget);
    expect(find.text('산책 중이에요 · 눌러서 돌아가기'), findsOneWidget);
    expect(find.text('산책 계속'), findsOneWidget);
    await tester.tap(find.byKey(const Key('walk-feed-banner')));
    await tester.tap(find.byKey(const Key('walk-feed-start-button')));
    expect(started, 2);
  });

  testWidgets('멈춘 세션이면 배너가 멈췄다고 말하고 연두 점이 없다', (tester) async {
    current = TrackerState.tracking(
      walkSession(distanceMeters: 300, pausedAt: t0),
    );

    await pump(tester, disableAnimations: true);

    expect(find.byKey(const Key('walk-feed-banner')), findsOneWidget);
    expect(find.byKey(const Key('walk-feed-banner-paused')), findsOneWidget);
    expect(find.text('산책을 잠시 멈췄어요'), findsOneWidget);
    expect(find.text('산책 중이에요 · 눌러서 돌아가기'), findsNothing);
    expect(find.byType(PulseDot), findsNothing);
  });

  testWidgets('추적 중 배너에는 연두 점이 있고 멈춤 표시는 없다', (tester) async {
    current = TrackerState.tracking(walkSession(distanceMeters: 300));

    await pump(tester, disableAnimations: true);

    expect(find.byType(PulseDot), findsOneWidget);
    expect(find.byKey(const Key('walk-feed-banner-paused')), findsNothing);
  });

  testWidgets('저장 안 한 산책 배너는 onSaveWalk 를 부르고 시작 버튼은 없다', (tester) async {
    current = TrackerState.finished(walkSession(endedAt: t1));
    var saved = 0;
    var started = 0;

    await pump(tester, onSaveWalk: () => saved++, onStartWalk: () => started++);

    expect(find.text('저장하지 않은 산책이 있어요 · 눌러서 저장하기'), findsOneWidget);
    expect(find.byKey(const Key('walk-feed-start-button')), findsNothing);
    await tester.tap(find.byKey(const Key('walk-feed-banner')));
    expect(saved, 1);
    expect(started, 0);
  });

  testWidgets('앱바 액션은 onOpenDogs 를 부른다', (tester) async {
    var opened = 0;

    await pump(tester, onOpenDogs: () => opened++);
    await tester.tap(find.byKey(const Key('walk-feed-open-dogs')));

    expect(opened, 1);
  });

  testWidgets('타임라인 위에 이번 주 요약 줄, 탭하면 통계로', (tester) async {
    var opened = 0;
    await pump(tester, onOpenStats: () => opened++);

    expect(find.text('이번 주 1.2 km · 1번'), findsOneWidget);
    await tester.tap(find.byKey(const Key('walk-feed-week-summary')));
    expect(opened, 1);
  });

  testWidgets('요약 줄은 스크린리더에 버튼으로 읽힌다', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    expect(
      tester.getSemantics(find.byKey(const Key('walk-feed-week-summary'))),
      matchesSemantics(
        label: '이번 주 1.2 km · 1번',
        isButton: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('앱이 다시 돌아오면 이번 주 요약을 지금 시각으로 다시 잡는다', (tester) async {
    var now = DateTime(2026, 10, 3, 12);
    getIt.unregister<WalkFeedCubit>();
    getIt.registerFactory<WalkFeedCubit>(
      () => WalkFeedCubit(useCase, FakeClock(() => now)),
    );
    await pump(tester);
    expect(find.text('이번 주 1.2 km · 1번'), findsOneWidget);

    now = DateTime(2026, 10, 5, 8); // 다음 주 월요일
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('이번 주는 아직 산책 전이에요'), findsOneWidget);
  });

  testWidgets('이번 주 산책이 없으면 아직 전이라고 말한다', (tester) async {
    when(() => useCase.watchWalks()).thenAnswer(
      (_) =>
          Stream.value(Ok([_walk('old', startedAt: DateTime(2026, 9, 1, 9))])),
    );

    await pump(tester);

    expect(find.text('이번 주는 아직 산책 전이에요'), findsOneWidget);
  });

  testWidgets('빈 피드에는 요약 줄이 없다', (tester) async {
    when(
      () => useCase.watchWalks(),
    ).thenAnswer((_) => Stream.value(const Ok([])));

    await pump(tester);

    expect(find.byKey(const Key('walk-feed-week-summary')), findsNothing);
  });

  testWidgets('실패는 재시도 버튼을 보이고 누르면 다시 구독한다', (tester) async {
    var calls = 0;
    when(() => useCase.watchWalks()).thenAnswer(
      (_) => Stream.value(
        calls++ == 0 ? const Err(Failure.unknown()) : Ok([_walk('a')]),
      ),
    );

    await pump(tester);
    expect(find.byKey(const Key('walk-feed-retry')), findsOneWidget);

    await tester.tap(find.byKey(const Key('walk-feed-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('walk-feed-entry-a')), findsOneWidget);
    expect(calls, 2);
  });

  group('백업 메뉴', () {
    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('walk-feed-more')));
      await tester.pumpAndSettle();
    }

    Future<void> choose(WidgetTester tester, String key) async {
      await openMenu(tester);
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    testWidgets('더보기에 내보내기 · 가져오기 두 항목이 있다', (tester) async {
      await pump(tester);

      expect(find.byTooltip('더보기'), findsOneWidget);
      await openMenu(tester);

      expect(find.byKey(const Key('walk-feed-backup-export')), findsOneWidget);
      expect(find.byKey(const Key('walk-feed-backup-import')), findsOneWidget);
      expect(find.text('백업 내보내기'), findsOneWidget);
      expect(find.text('백업 가져오기'), findsOneWidget);
    });

    testWidgets('내보내기에 성공하면 스낵바가 없다', (tester) async {
      when(
        () => useCase.exportBackup(),
      ).thenAnswer((_) async => const Ok(null));
      await pump(tester);

      await choose(tester, 'walk-feed-backup-export');

      verify(() => useCase.exportBackup()).called(1);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('내보내기에 실패하면 스낵바로 알린다', (tester) async {
      when(
        () => useCase.exportBackup(),
      ).thenAnswer((_) async => const Err(Failure.unknown()));
      await pump(tester);

      await choose(tester, 'walk-feed-backup-export');

      expect(find.text('백업을 만들지 못했어요'), findsOneWidget);
    });

    for (final (result, message) in [
      (const BackupImportResult.imported(1, 2), '반려견 1마리 · 산책 2개를 가져왔어요'),
      (const BackupImportResult.nothingNew(), '새로 가져올 기록이 없어요'),
      (const BackupImportResult.invalid(), '백업 파일을 읽지 못했어요'),
      (const BackupImportResult.failed(Failure.unknown()), '가져오지 못했어요'),
    ]) {
      testWidgets('가져오기 결과 $result 는 "$message" 스낵바', (tester) async {
        when(() => useCase.importBackup()).thenAnswer((_) async => result);
        await pump(tester);

        await choose(tester, 'walk-feed-backup-import');

        verify(() => useCase.importBackup()).called(1);
        expect(find.text(message), findsOneWidget);
      });
    }

    testWidgets('파일 고르기를 취소하면 아무것도 보이지 않는다', (tester) async {
      when(
        () => useCase.importBackup(),
      ).thenAnswer((_) async => const BackupImportResult.cancelled());
      await pump(tester);

      await choose(tester, 'walk-feed-backup-import');

      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
