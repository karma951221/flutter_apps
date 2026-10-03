import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fakes.dart';
import '../../support/mock_walk_use_case.dart';
import '../../support/pump_app.dart';
import '../../support/stub_tile_provider.dart';

void main() {
  late MockWalkUseCase useCase;
  late TrackerState current;
  late StreamController<TrackerState> states;

  final now = t0.add(const Duration(minutes: 5, seconds: 7));

  setUp(() {
    registerFallbacks();
    useCase = MockWalkUseCase();
    current = const TrackerState.idle();
    states = StreamController<TrackerState>.broadcast();
    when(() => useCase.trackerState).thenAnswer((_) => current);
    when(() => useCase.trackerStates).thenAnswer((_) => states.stream);
    when(
      () => useCase.getDogs(),
    ).thenAnswer((_) async => Ok([dog('1'), dog('2')]));
    getIt
      ..registerFactory<ActiveWalkCubit>(
        () => ActiveWalkCubit.withClock(useCase, () => now),
      )
      ..registerSingleton<TileProvider>(StubTileProvider());
  });
  tearDown(() async {
    await states.close();
    await getIt.reset();
  });

  /// 주기 타이머가 남지 않도록 페이지를 내린다.
  Future<void> disposePage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  final trackingSession = walkSession(
    points: [trackPoint(37.5), trackPoint(37.501)],
    distanceMeters: 1250,
  );

  testWidgets('반려견 선택을 모두 해제하면 시작 버튼이 비활성이 된다', (tester) async {
    await pumpApp(tester, ActiveWalkPage(onStopped: () {}, onOpenDogs: () {}));

    AppButton startButton() => tester.widget<AppButton>(
      find.byKey(const Key('walk-active-start-button')),
    );
    expect(startButton().onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('walk-active-dog-chip-1')));
    await tester.tap(find.byKey(const Key('walk-active-dog-chip-2')));
    await tester.pumpAndSettle();

    expect(startButton().onPressed, isNull);
  });

  testWidgets('시작하면 선택한 반려견과 알림 문구로 startWalk 를 부른다', (tester) async {
    when(
      () => useCase.startWalk(
        dogIds: any(named: 'dogIds'),
        notice: any(named: 'notice'),
      ),
    ).thenAnswer((_) async {
      current = TrackerState.tracking(trackingSession);
      return const Ok(null);
    });
    await pumpApp(tester, ActiveWalkPage(onStopped: () {}, onOpenDogs: () {}));

    await tester.tap(find.byKey(const Key('walk-active-dog-chip-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('walk-active-start-button')));
    await tester.pumpAndSettle();

    verify(
      () => useCase.startWalk(
        dogIds: ['1'],
        notice: const TrackingNotice(
          title: '산책을 기록하고 있어요',
          text: '앱을 닫아도 경로가 계속 기록됩니다',
        ),
      ),
    ).called(1);
    expect(find.byKey(const Key('walk-active-stop-button')), findsOneWidget);
    await disposePage(tester);
  });

  testWidgets('추적 중에는 지도와 경과 시간 · 거리가 보인다', (tester) async {
    current = TrackerState.tracking(trackingSession);

    await pumpApp(tester, ActiveWalkPage(onStopped: () {}, onOpenDogs: () {}));

    expect(find.byKey(const Key('walk-active-map')), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('walk-active-elapsed'))).data,
      '05:07',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('walk-active-distance'))).data,
      '1.3 km',
    );
    verifyNever(() => useCase.getDogs());
    await disposePage(tester);
  });

  testWidgets('추적을 시작했지만 점이 없으면 위치를 찾는 중 문구를 보인다', (tester) async {
    current = TrackerState.tracking(walkSession());

    await pumpApp(tester, ActiveWalkPage(onStopped: () {}, onOpenDogs: () {}));

    expect(find.byType(FlutterMap), findsNothing);
    expect(find.text('위치를 찾는 중…'), findsOneWidget);
    await disposePage(tester);
  });

  testWidgets('종료를 확인하면 stopWalk 후 onStopped 를 한 번 부른다', (tester) async {
    current = TrackerState.tracking(trackingSession);
    final ended = walkSession(
      points: trackingSession.points,
      distanceMeters: 1250,
      endedAt: now,
    );
    when(() => useCase.stopWalk()).thenAnswer((_) async {
      current = TrackerState.finished(ended);
      states.add(current);
      return Ok(ended);
    });
    var stopped = 0;
    await pumpApp(
      tester,
      ActiveWalkPage(onStopped: () => stopped++, onOpenDogs: () {}),
    );

    await tester.tap(find.byKey(const Key('walk-active-stop-button')));
    await tester.pumpAndSettle();
    expect(find.text('산책을 끝낼까요?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('산책 종료'),
      ),
    );
    await tester.pumpAndSettle();

    verify(() => useCase.stopWalk()).called(1);
    expect(stopped, 1);
    await disposePage(tester);
  });

  testWidgets('종료 확인을 취소하면 stopWalk 도 onStopped 도 부르지 않는다', (tester) async {
    current = TrackerState.tracking(trackingSession);
    var stopped = 0;
    await pumpApp(
      tester,
      ActiveWalkPage(onStopped: () => stopped++, onOpenDogs: () {}),
    );

    await tester.tap(find.byKey(const Key('walk-active-stop-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    verifyNever(() => useCase.stopWalk());
    expect(stopped, 0);
    await disposePage(tester);
  });

  testWidgets('저장 안 된 종료 세션으로 들어오면 곧바로 onStopped 를 부른다', (tester) async {
    current = TrackerState.finished(trackingSession);
    var stopped = 0;

    await pumpApp(
      tester,
      ActiveWalkPage(onStopped: () => stopped++, onOpenDogs: () {}),
    );

    expect(stopped, 1);
  });

  testWidgets('위치 권한을 거부하면 안내와 재시도를 보이고 재시도는 startWalk 를 다시 부른다', (
    tester,
  ) async {
    when(
      () => useCase.startWalk(
        dogIds: any(named: 'dogIds'),
        notice: any(named: 'notice'),
      ),
    ).thenAnswer(
      (_) async => const Err(
        Failure.forbidden(failureCode: FailureCode.locationPermissionDenied),
      ),
    );
    await pumpApp(tester, ActiveWalkPage(onStopped: () {}, onOpenDogs: () {}));

    await tester.tap(find.byKey(const Key('walk-active-start-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('walk-active-failure')), findsOneWidget);
    expect(find.text('설정에서 위치 권한을 허용한 뒤 다시 시도해 주세요'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    verify(
      () => useCase.startWalk(
        dogIds: any(named: 'dogIds'),
        notice: any(named: 'notice'),
      ),
    ).called(2);
  });

  testWidgets('반려견이 0마리면 등록 안내를 보이고 버튼은 onOpenDogs 를 부른다', (tester) async {
    when(() => useCase.getDogs()).thenAnswer((_) async => const Ok([]));
    var opened = 0;

    await pumpApp(
      tester,
      ActiveWalkPage(onStopped: () {}, onOpenDogs: () => opened++),
    );

    expect(find.byType(AppPlaceholder), findsOneWidget);
    expect(find.byKey(const Key('walk-active-start-button')), findsNothing);
    await tester.tap(find.text('반려견 등록하기'));
    expect(opened, 1);
  });
}
