import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:fake_async/fake_async.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fakes.dart';
import '../../support/mock_walk_use_case.dart';

const _notice = TrackingNotice(title: '제목', text: '본문');
const _denied = Failure.forbidden(
  failureCode: FailureCode.locationPermissionDenied,
);

void main() {
  late MockWalkUseCase useCase;
  late TrackerState current;

  final now = t0.add(const Duration(minutes: 5));
  final session = walkSession(points: [trackPoint(37.5)]);

  setUp(() {
    registerFallbacks();
    useCase = MockWalkUseCase();
    current = const TrackerState.idle();
    when(() => useCase.trackerState).thenAnswer((_) => current);
    when(() => useCase.trackerStates).thenAnswer((_) => const Stream.empty());
    when(
      () => useCase.watchDogs(),
    ).thenAnswer((_) => Stream.value(Ok([dog('1'), dog('2')])));
  });

  ActiveWalkCubit build() => ActiveWalkCubit.withClock(useCase, () => now);

  blocTest<ActiveWalkCubit, ActiveWalkState>(
    '반려견 목록으로 selectingDogs 로 시작하고 전부 선택돼 있다',
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      ActiveWalkState.selectingDogs(
        dogs: [dog('1'), dog('2')],
        selectedIds: const {'1', '2'},
      ),
    ],
  );

  blocTest<ActiveWalkCubit, ActiveWalkState>(
    '반려견이 0마리면 빈 selectingDogs 가 되고 시작하지 않는다',
    setUp: () => when(
      () => useCase.watchDogs(),
    ).thenAnswer((_) => Stream.value(const Ok([]))),
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.start(_notice);
    },
    expect: () => [
      const ActiveWalkState.selectingDogs(dogs: [], selectedIds: {}),
    ],
    verify: (_) => verifyNever(
      () => useCase.startWalk(
        dogIds: any(named: 'dogIds'),
        notice: any(named: 'notice'),
      ),
    ),
  );

  blocTest<ActiveWalkCubit, ActiveWalkState>(
    '반려견을 등록하고 돌아오면 목록이 갱신된다',
    setUp: () {
      final controller = StreamController<Result<List<Dog>>>();
      addTearDown(controller.close);
      when(() => useCase.watchDogs()).thenAnswer((_) => controller.stream);
      Future.microtask(() => controller.add(const Ok([])));
      Future.delayed(
        const Duration(milliseconds: 10),
        () => controller.add(Ok([dog('1')])),
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await Future<void>.delayed(const Duration(milliseconds: 30));
    },
    expect: () => [
      const ActiveWalkState.selectingDogs(dogs: [], selectedIds: {}),
      ActiveWalkState.selectingDogs(dogs: [dog('1')], selectedIds: const {'1'}),
    ],
  );

  blocTest<ActiveWalkCubit, ActiveWalkState>(
    '추적 중 재진입은 반려견 조회 없이 tracking 으로 시작한다',
    setUp: () => current = TrackerState.tracking(session),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      ActiveWalkState.tracking(
        session: session,
        elapsed: const Duration(minutes: 5),
      ),
    ],
    verify: (_) => verifyNever(() => useCase.watchDogs()),
  );

  blocTest<ActiveWalkCubit, ActiveWalkState>(
    'finished 재진입은 stopped 로 시작한다',
    setUp: () => current = TrackerState.finished(session),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [ActiveWalkState.stopped(session)],
    verify: (_) => verifyNever(() => useCase.watchDogs()),
  );

  blocTest<ActiveWalkCubit, ActiveWalkState>(
    'toggleDog 은 선택을 넣고 뺀다',
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit
        ..toggleDog('1')
        ..toggleDog('1');
    },
    skip: 1,
    expect: () => [
      ActiveWalkState.selectingDogs(
        dogs: [dog('1'), dog('2')],
        selectedIds: const {'2'},
      ),
      ActiveWalkState.selectingDogs(
        dogs: [dog('1'), dog('2')],
        selectedIds: const {'1', '2'},
      ),
    ],
  );

  blocTest<ActiveWalkCubit, ActiveWalkState>(
    'start 성공은 선택한 반려견으로 startWalk 를 부르고 starting 뒤 tracking 이 된다',
    setUp: () =>
        when(
          () => useCase.startWalk(
            dogIds: any(named: 'dogIds'),
            notice: any(named: 'notice'),
          ),
        ).thenAnswer((_) async {
          current = TrackerState.tracking(session);
          return const Ok(null);
        }),
    build: build,
    act: (cubit) async {
      await cubit.load();
      cubit.toggleDog('1');
      await cubit.start(_notice);
    },
    skip: 2,
    expect: () => [
      ActiveWalkState.starting(
        dogs: [dog('1'), dog('2')],
        selectedIds: const {'2'},
      ),
      ActiveWalkState.tracking(
        session: session,
        elapsed: const Duration(minutes: 5),
      ),
    ],
    verify: (_) => verify(
      () => useCase.startWalk(dogIds: ['2'], notice: _notice),
    ).called(1),
  );

  blocTest<ActiveWalkCubit, ActiveWalkState>(
    '권한 거부는 starting 뒤 선택을 유지한 failure 가 되고 재시도는 같은 알림 문구로 다시 시작한다',
    setUp: () => when(
      () => useCase.startWalk(
        dogIds: any(named: 'dogIds'),
        notice: any(named: 'notice'),
      ),
    ).thenAnswer((_) async => const Err(_denied)),
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.start(_notice);
      await cubit.retry();
    },
    skip: 1,
    expect: () {
      final dogs = [dog('1'), dog('2')];
      const ids = {'1', '2'};
      return [
        ActiveWalkState.starting(dogs: dogs, selectedIds: ids),
        ActiveWalkState.failure(failure: _denied, dogs: dogs, selectedIds: ids),
        ActiveWalkState.starting(dogs: dogs, selectedIds: ids),
        ActiveWalkState.failure(failure: _denied, dogs: dogs, selectedIds: ids),
      ];
    },
    verify: (_) => verify(
      () => useCase.startWalk(dogIds: ['1', '2'], notice: _notice),
    ).called(2),
  );

  blocTest<ActiveWalkCubit, ActiveWalkState>(
    '반려견 조회 실패의 재시도는 다시 읽는다',
    setUp: () {
      var calls = 0;
      when(() => useCase.watchDogs()).thenAnswer(
        (_) => Stream.value(
          calls++ == 0 ? const Err(Failure.unknown()) : Ok([dog('1')]),
        ),
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.retry();
    },
    expect: () => [
      const ActiveWalkState.failure(
        failure: Failure.unknown(),
        dogs: [],
        selectedIds: {},
      ),
      ActiveWalkState.selectingDogs(dogs: [dog('1')], selectedIds: const {'1'}),
    ],
  );

  blocTest<ActiveWalkCubit, ActiveWalkState>(
    'stop 성공은 stopped 를 한 번만 낸다 (구독이 먼저 finished 를 줘도)',
    setUp: () {
      current = TrackerState.tracking(session);
      final ended = walkSession(endedAt: now);
      final controller = StreamController<TrackerState>.broadcast();
      when(() => useCase.trackerStates).thenAnswer((_) => controller.stream);
      when(() => useCase.stopWalk()).thenAnswer((_) async {
        controller.add(TrackerState.finished(ended));
        await Future<void>.delayed(Duration.zero);
        return Ok(ended);
      });
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.stop();
    },
    skip: 1,
    expect: () => [ActiveWalkState.stopped(walkSession(endedAt: now))],
  );

  blocTest<ActiveWalkCubit, ActiveWalkState>(
    'stop 실패는 failure 가 되고 재시도는 추적 상태를 다시 읽는다',
    setUp: () {
      current = TrackerState.tracking(session);
      when(
        () => useCase.stopWalk(),
      ).thenAnswer((_) async => const Err(Failure.unknown()));
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.stop();
      await cubit.retry();
    },
    skip: 1,
    expect: () => [
      const ActiveWalkState.failure(
        failure: Failure.unknown(),
        dogs: [],
        selectedIds: {},
      ),
      ActiveWalkState.tracking(
        session: session,
        elapsed: const Duration(minutes: 5),
      ),
    ],
  );

  test('1초마다 elapsed 가 다시 계산돼 늘어나고 close 뒤에는 멈춘다', () {
    fakeAsync((async) {
      current = TrackerState.tracking(walkSession());
      final clock = async.getClock(t0);
      final cubit = ActiveWalkCubit.withClock(useCase, clock.now);
      final elapsed = <Duration>[];
      cubit.stream.listen((state) {
        if (state case ActiveWalkTracking(elapsed: final e)) elapsed.add(e);
      });

      cubit.load();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 3));
      expect(elapsed, [
        Duration.zero,
        const Duration(seconds: 1),
        const Duration(seconds: 2),
        const Duration(seconds: 3),
      ]);

      cubit.close();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 3));
      expect(elapsed, hasLength(4));
    });
  });
}
