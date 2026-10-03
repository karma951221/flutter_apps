import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fakes.dart';
import '../../support/mock_walk_use_case.dart';

void main() {
  late MockWalkUseCase useCase;
  late TrackerState current;
  late StreamController<TrackerState> trackerController;

  final session = walkSession(points: [trackPoint(37.5)]);

  setUp(() {
    useCase = MockWalkUseCase();
    current = const TrackerState.idle();
    trackerController = StreamController<TrackerState>.broadcast();
    when(() => useCase.trackerState).thenAnswer((_) => current);
    when(
      () => useCase.trackerStates,
    ).thenAnswer((_) => trackerController.stream);
  });
  tearDown(() => trackerController.close());

  blocTest<WalkFeedCubit, WalkFeedState>(
    '스트림이 바뀌면 loaded 가 갱신된다',
    setUp: () => when(() => useCase.watchWalks()).thenAnswer(
      (_) => Stream.fromIterable([
        Ok([walk(), walk()]),
        Ok([walk()]),
      ]),
    ),
    build: () => WalkFeedCubit(useCase),
    act: (cubit) => cubit.start(),
    expect: () => [
      const WalkFeedState.loading(),
      WalkFeedState.loaded(
        walks: [walk(), walk()],
        tracker: const TrackerState.idle(),
      ),
      WalkFeedState.loaded(walks: [walk()], tracker: const TrackerState.idle()),
    ],
  );

  blocTest<WalkFeedCubit, WalkFeedState>(
    '추적 중이면 tracker 가 tracking 이다',
    setUp: () {
      current = TrackerState.tracking(session);
      when(
        () => useCase.watchWalks(),
      ).thenAnswer((_) => Stream.value(Ok([walk()])));
    },
    build: () => WalkFeedCubit(useCase),
    act: (cubit) => cubit.start(),
    expect: () => [
      const WalkFeedState.loading(),
      WalkFeedState.loaded(
        walks: [walk()],
        tracker: TrackerState.tracking(session),
      ),
    ],
  );

  blocTest<WalkFeedCubit, WalkFeedState>(
    'finished 면 tracker 가 finished 다',
    setUp: () {
      final ended = walkSession(endedAt: t1);
      when(() => useCase.watchWalks()).thenAnswer((_) {
        Future<void>.delayed(
          const Duration(milliseconds: 5),
          () => trackerController.add(TrackerState.finished(ended)),
        );
        return Stream.value(Ok([walk()]));
      });
    },
    build: () => WalkFeedCubit(useCase),
    act: (cubit) async {
      await cubit.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    expect: () => [
      const WalkFeedState.loading(),
      WalkFeedState.loaded(walks: [walk()], tracker: const TrackerState.idle()),
      WalkFeedState.loaded(
        walks: [walk()],
        tracker: TrackerState.finished(walkSession(endedAt: t1)),
      ),
    ],
  );

  blocTest<WalkFeedCubit, WalkFeedState>(
    '목록 전에 온 tracker 변화는 loading 을 유지하고 첫 loaded 에 반영된다',
    setUp: () => when(() => useCase.watchWalks()).thenAnswer(
      (_) => Stream<Result<List<Walk>>>.fromFuture(
        Future.delayed(const Duration(milliseconds: 10), () => Ok([walk()])),
      ),
    ),
    build: () => WalkFeedCubit(useCase),
    act: (cubit) async {
      await cubit.start();
      trackerController.add(TrackerState.tracking(session));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    },
    expect: () => [
      const WalkFeedState.loading(),
      WalkFeedState.loaded(
        walks: [walk()],
        tracker: TrackerState.tracking(session),
      ),
    ],
  );

  blocTest<WalkFeedCubit, WalkFeedState>(
    '스트림이 Err 를 내면 failure 가 된다',
    setUp: () => when(
      () => useCase.watchWalks(),
    ).thenAnswer((_) => Stream.value(const Err(Failure.unknown()))),
    build: () => WalkFeedCubit(useCase),
    act: (cubit) => cubit.start(),
    expect: () => [
      const WalkFeedState.loading(),
      const WalkFeedState.failure(Failure.unknown()),
    ],
  );

  blocTest<WalkFeedCubit, WalkFeedState>(
    'retry 는 산책 스트림을 다시 구독한다',
    setUp: () {
      var calls = 0;
      when(() => useCase.watchWalks()).thenAnswer(
        (_) => Stream.value(
          calls++ == 0 ? const Err(Failure.unknown()) : Ok([walk()]),
        ),
      );
    },
    build: () => WalkFeedCubit(useCase),
    act: (cubit) async {
      await cubit.start();
      await Future<void>.delayed(Duration.zero);
      await cubit.retry();
    },
    expect: () => [
      const WalkFeedState.loading(),
      const WalkFeedState.failure(Failure.unknown()),
      const WalkFeedState.loading(),
      WalkFeedState.loaded(walks: [walk()], tracker: const TrackerState.idle()),
    ],
    verify: (_) => verify(() => useCase.watchWalks()).called(2),
  );

  test('닫힌 뒤에 온 값은 상태를 내지 않고 구독을 끊는다', () async {
    final controller = StreamController<Result<List<Walk>>>();
    when(() => useCase.watchWalks()).thenAnswer((_) => controller.stream);
    final cubit = WalkFeedCubit(useCase);
    await cubit.start();
    await cubit.close();

    controller.add(Ok([walk()]));
    trackerController.add(TrackerState.tracking(session));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, const WalkFeedState.loading());
    expect(controller.hasListener, isFalse);
    expect(trackerController.hasListener, isFalse);
    await controller.close();
  });
}
