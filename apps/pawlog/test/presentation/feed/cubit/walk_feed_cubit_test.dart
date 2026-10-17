import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/domain/backup/entity/backup_import_result.dart';
import 'package:pawlog/domain/stats/entity/period_summary.dart';
import 'package:pawlog/domain/tracking/entity/tracker_state.dart';
import 'package:pawlog/domain/walk/entity/walk.dart';
import 'package:pawlog/presentation/feed/cubit/walk_feed_cubit.dart';
import 'package:pawlog/presentation/feed/cubit/walk_feed_state.dart';

import '../../../support/fakes.dart';
import '../../../support/mock_walk_use_case.dart';

void main() {
  final clock = FakeClock.fixed(DateTime(2026, 12, 1));
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
    build: () => WalkFeedCubit(useCase, clock),
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
    build: () => WalkFeedCubit(useCase, clock),
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
    build: () => WalkFeedCubit(useCase, clock),
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
    build: () => WalkFeedCubit(useCase, clock),
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
    build: () => WalkFeedCubit(useCase, clock),
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
    build: () => WalkFeedCubit(useCase, clock),
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

  blocTest<WalkFeedCubit, WalkFeedState>(
    '이번 주 요약을 시계 기준으로 싣고, 추적 상태가 바뀌어도 유지한다',
    setUp: () => when(() => useCase.watchWalks()).thenAnswer((_) {
      Future<void>.delayed(
        const Duration(milliseconds: 5),
        () => trackerController.add(TrackerState.tracking(session)),
      );
      return Stream.value(Ok([walk()]));
    }),
    // t0 = 2026-10-03(토) 09:00 → 같은 주의 일요일
    build: () =>
        WalkFeedCubit(useCase, FakeClock.fixed(DateTime(2026, 10, 4, 12))),
    act: (cubit) async {
      await cubit.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    expect: () {
      const summary = PeriodSummary(
        distanceMeters: 1200,
        duration: Duration(minutes: 30),
        walkCount: 1,
      );
      return [
        const WalkFeedState.loading(),
        WalkFeedState.loaded(
          walks: [walk()],
          tracker: const TrackerState.idle(),
          weekSummary: summary,
        ),
        WalkFeedState.loaded(
          walks: [walk()],
          tracker: TrackerState.tracking(session),
          weekSummary: summary,
        ),
      ];
    },
  );

  group('refreshWeekSummary', () {
    // t0 = 2026-10-03(토) → 처음엔 같은 주 일요일, 다음엔 다음 주 월요일.
    var now = DateTime(2026, 10, 4, 12);
    const summary = PeriodSummary(
      distanceMeters: 1200,
      duration: Duration(minutes: 30),
      walkCount: 1,
    );

    blocTest<WalkFeedCubit, WalkFeedState>(
      '주 경계를 넘긴 뒤 부르면 캐시한 목록으로 빈 요약을 낸다',
      setUp: () {
        now = DateTime(2026, 10, 4, 12);
        when(
          () => useCase.watchWalks(),
        ).thenAnswer((_) => Stream.value(Ok([walk()])));
      },
      build: () => WalkFeedCubit(useCase, FakeClock(() => now)),
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        now = DateTime(2026, 10, 5, 8);
        cubit.refreshWeekSummary();
      },
      expect: () => [
        const WalkFeedState.loading(),
        WalkFeedState.loaded(
          walks: [walk()],
          tracker: const TrackerState.idle(),
          weekSummary: summary,
        ),
        WalkFeedState.loaded(
          walks: [walk()],
          tracker: const TrackerState.idle(),
        ),
      ],
      verify: (_) => verify(() => useCase.watchWalks()).called(1),
    );

    blocTest<WalkFeedCubit, WalkFeedState>(
      '목록이 아직 없으면 아무것도 내지 않는다',
      build: () => WalkFeedCubit(useCase, clock),
      act: (cubit) => cubit.refreshWeekSummary(),
      expect: () => <WalkFeedState>[],
    );
  });

  group('toggleFavoritesOnly', () {
    blocTest<WalkFeedCubit, WalkFeedState>(
      '필터를 켜고 끄며, 켠 채로 새 목록이 와도 유지한다',
      setUp: () {
        final controller = StreamController<Result<List<Walk>>>();
        addTearDown(controller.close);
        when(() => useCase.watchWalks()).thenAnswer((_) => controller.stream);
        controller.add(Ok([walk()]));
        Future<void>.delayed(
          const Duration(milliseconds: 10),
          () => controller.add(const Ok([])),
        );
      },
      build: () => WalkFeedCubit(useCase, clock),
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        cubit.toggleFavoritesOnly();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        cubit.toggleFavoritesOnly();
      },
      expect: () => [
        const WalkFeedState.loading(),
        WalkFeedState.loaded(
          walks: [walk()],
          tracker: const TrackerState.idle(),
        ),
        WalkFeedState.loaded(
          walks: [walk()],
          tracker: const TrackerState.idle(),
          favoritesOnly: true,
        ),
        const WalkFeedState.loaded(
          walks: [],
          tracker: TrackerState.idle(),
          favoritesOnly: true,
        ),
        const WalkFeedState.loaded(walks: [], tracker: TrackerState.idle()),
      ],
    );

    blocTest<WalkFeedCubit, WalkFeedState>(
      'loaded 전에는 아무것도 내지 않는다',
      build: () => WalkFeedCubit(useCase, clock),
      act: (cubit) => cubit.toggleFavoritesOnly(),
      expect: () => <WalkFeedState>[],
    );
  });

  test('닫힌 뒤에 온 값은 상태를 내지 않고 구독을 끊는다', () async {
    final controller = StreamController<Result<List<Walk>>>();
    when(() => useCase.watchWalks()).thenAnswer((_) => controller.stream);
    final cubit = WalkFeedCubit(useCase, clock);
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

  group('백업', () {
    setUp(
      () => when(
        () => useCase.watchWalks(),
      ).thenAnswer((_) => Stream.value(const Ok([]))),
    );

    test('내보내기 · 가져오기는 유스케이스 결과를 그대로 돌려주고 상태를 바꾸지 않는다', () async {
      when(
        () => useCase.exportBackup(),
      ).thenAnswer((_) async => const Err(Failure.unknown()));
      when(
        () => useCase.importBackup(),
      ).thenAnswer((_) async => const BackupImportResult.imported(1, 2));
      final cubit = WalkFeedCubit(useCase, clock);
      final states = <WalkFeedState>[];
      final sub = cubit.stream.listen(states.add);

      expect(await cubit.exportBackup(), const Err<void>(Failure.unknown()));
      expect(
        await cubit.importBackup(),
        const BackupImportResult.imported(1, 2),
      );
      await Future<void>.delayed(Duration.zero);

      expect(states, isEmpty);
      await sub.cancel();
      await cubit.close();
    });

    test('진행 중에 다시 부르면 유스케이스를 또 부르지 않는다', () async {
      final exporting = Completer<Result<void>>();
      final importing = Completer<BackupImportResult>();
      when(() => useCase.exportBackup()).thenAnswer((_) => exporting.future);
      when(() => useCase.importBackup()).thenAnswer((_) => importing.future);
      final cubit = WalkFeedCubit(useCase, clock);

      final first = cubit.exportBackup();
      expect(await cubit.exportBackup(), const Ok<void>(null));
      expect(await cubit.importBackup(), const BackupImportResult.cancelled());
      exporting.complete(const Ok(null));
      await first;

      final second = cubit.importBackup();
      expect(await cubit.importBackup(), const BackupImportResult.cancelled());
      importing.complete(const BackupImportResult.nothingNew());
      expect(await second, const BackupImportResult.nothingNew());

      verify(() => useCase.exportBackup()).called(1);
      verify(() => useCase.importBackup()).called(1);
      await cubit.close();
    });
  });
}
