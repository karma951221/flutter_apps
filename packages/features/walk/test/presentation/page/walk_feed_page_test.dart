import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fakes.dart';
import '../../support/mock_walk_use_case.dart';
import '../../support/pump_app.dart';

Walk _walk(String id, {String? memo, List<WalkPhoto> photos = const []}) =>
    Walk(
      id: id,
      startedAt: t0,
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
    getIt.registerFactory<WalkFeedCubit>(() => WalkFeedCubit(useCase));
  });
  tearDown(getIt.reset);

  Future<void> pump(
    WidgetTester tester, {
    VoidCallback? onStartWalk,
    VoidCallback? onSaveWalk,
    ValueChanged<String>? onOpenWalk,
    VoidCallback? onOpenDogs,
  }) => pumpApp(
    tester,
    WalkFeedPage(
      onStartWalk: onStartWalk ?? () {},
      onSaveWalk: onSaveWalk ?? () {},
      onOpenWalk: onOpenWalk ?? (_) {},
      onOpenDogs: onOpenDogs ?? () {},
    ),
  );

  testWidgets('빈 피드는 AppPlaceholder 와 시작 버튼을 보이고 FAB 는 없다', (tester) async {
    when(
      () => useCase.watchWalks(),
    ).thenAnswer((_) => Stream.value(const Ok([])));
    var started = 0;

    await pump(tester, onStartWalk: () => started++);

    expect(find.byType(AppPlaceholder), findsOneWidget);
    expect(find.text('첫 산책을 시작해 보세요'), findsOneWidget);
    expect(find.byKey(const Key('walk-feed-fab')), findsNothing);
    await tester.tap(find.text('산책 시작'));
    expect(started, 1);
  });

  testWidgets('카드에 반려견 · 거리 · 시간 · 메모가 보인다', (tester) async {
    await pump(tester);

    expect(find.byKey(const Key('walk-feed-card-a')), findsOneWidget);
    expect(find.text('콩이1'), findsNothing); // 아바타는 이니셜만 그린다
    expect(find.byType(DogAvatars), findsOneWidget);
    expect(find.textContaining('1.2 km'), findsOneWidget);
    expect(find.textContaining('30분'), findsOneWidget);
    expect(find.text('공원 한 바퀴'), findsOneWidget);
    expect(find.text('2026.10.03 09:00'), findsOneWidget);
  });

  testWidgets('메모가 없으면 메모 줄이 없다', (tester) async {
    when(
      () => useCase.watchWalks(),
    ).thenAnswer((_) => Stream.value(Ok([_walk('a')])));

    await pump(tester);

    expect(find.text('공원 한 바퀴'), findsNothing);
    expect(find.byKey(const Key('walk-feed-card-a')), findsOneWidget);
  });

  testWidgets('카드를 탭하면 onOpenWalk(id) 를 부른다', (tester) async {
    String? opened;

    await pump(tester, onOpenWalk: (id) => opened = id);
    await tester.tap(find.byKey(const Key('walk-feed-card-a')));

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

  testWidgets('FAB 를 누르면 onStartWalk 를 부른다', (tester) async {
    var started = 0;

    await pump(tester, onStartWalk: () => started++);
    await tester.tap(find.byKey(const Key('walk-feed-fab')));

    expect(started, 1);
    expect(find.text('산책 시작'), findsOneWidget);
    expect(find.byKey(const Key('walk-feed-banner')), findsNothing);
  });

  testWidgets('추적 중이면 배너와 산책 계속 FAB 가 모두 onStartWalk 를 부른다', (tester) async {
    current = TrackerState.tracking(walkSession(distanceMeters: 300));
    var started = 0;

    await pump(tester, onStartWalk: () => started++);

    expect(find.byKey(const Key('walk-feed-banner')), findsOneWidget);
    expect(find.text('산책 중이에요 · 눌러서 돌아가기'), findsOneWidget);
    expect(find.text('산책 계속'), findsOneWidget);
    await tester.tap(find.byKey(const Key('walk-feed-banner')));
    await tester.tap(find.byKey(const Key('walk-feed-fab')));
    expect(started, 2);
  });

  testWidgets('저장 안 한 산책 배너는 onSaveWalk 를 부르고 FAB 는 없다', (tester) async {
    current = TrackerState.finished(walkSession(endedAt: t1));
    var saved = 0;
    var started = 0;

    await pump(tester, onSaveWalk: () => saved++, onStartWalk: () => started++);

    expect(find.text('저장하지 않은 산책이 있어요 · 눌러서 저장하기'), findsOneWidget);
    expect(find.byKey(const Key('walk-feed-fab')), findsNothing);
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

    expect(find.byKey(const Key('walk-feed-card-a')), findsOneWidget);
    expect(calls, 2);
  });
}
