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

  /// 피드 목록 스트림을 [answer] 로 정한다. [answer] 는 cubit 이 넘긴 limit · favoritesOnly 를 받는다.
  void stubRecent(
    Stream<Result<List<Walk>>> Function(int limit, bool favoritesOnly) answer,
  ) =>
      when(
        () => useCase.watchRecentWalks(
          limit: any(named: 'limit'),
          favoritesOnly: any(named: 'favoritesOnly'),
        ),
      ).thenAnswer(
        (inv) => answer(
          inv.namedArguments[#limit] as int,
          inv.namedArguments[#favoritesOnly] as bool,
        ),
      );

  void stubWalks(Stream<Result<List<Walk>>> Function() answer) =>
      stubRecent((_, _) => answer());

  void stubWeek(Stream<Result<List<Walk>>> Function() answer) =>
      when(() => useCase.watchWalksSince(any())).thenAnswer((_) => answer());

  void verifyRecent({required int limit, bool favoritesOnly = false}) => verify(
    () => useCase.watchRecentWalks(limit: limit, favoritesOnly: favoritesOnly),
  ).called(1);

  setUpAll(() => registerFallbackValue(DateTime(2000)));

  setUp(() {
    useCase = MockWalkUseCase();
    current = const TrackerState.idle();
    stubWeek(() => Stream.value(const Ok([])));
    trackerController = StreamController<TrackerState>.broadcast();
    when(() => useCase.trackerState).thenAnswer((_) => current);
    when(
      () => useCase.trackerStates,
    ).thenAnswer((_) => trackerController.stream);
  });
  tearDown(() => trackerController.close());

  blocTest<WalkFeedCubit, WalkFeedState>(
    '스트림이 바뀌면 loaded 가 갱신된다',
    setUp: () => stubWalks(
      () => Stream.fromIterable([
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
      stubWalks(() => Stream.value(Ok([walk()])));
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
      stubWalks(() {
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
    setUp: () => stubWalks(
      () => Stream<Result<List<Walk>>>.fromFuture(
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
    setUp: () => stubWalks(() => Stream.value(const Err(Failure.unknown()))),
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
      stubWalks(
        () => Stream.value(
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
    verify: (_) => verify(
      () => useCase.watchRecentWalks(limit: 30, favoritesOnly: false),
    ).called(2),
  );

  blocTest<WalkFeedCubit, WalkFeedState>(
    '이번 주 요약을 시계 기준으로 싣고, 추적 상태가 바뀌어도 유지한다',
    setUp: () {
      stubWeek(() => Stream.value(Ok([walk()])));
      stubWalks(() {
        Future<void>.delayed(
          const Duration(milliseconds: 5),
          () => trackerController.add(TrackerState.tracking(session)),
        );
        return Stream.value(Ok([walk()]));
      });
    },
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
      '주 경계를 넘긴 뒤 부르면 빈 요약을 내고 새 주 시작으로 다시 구독한다',
      setUp: () {
        now = DateTime(2026, 10, 4, 12);
        stubWalks(() => Stream.value(Ok([walk()])));
        stubWeek(() => Stream.value(Ok([walk()])));
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
      verify: (_) {
        verify(() => useCase.watchWalksSince(DateTime(2026, 9, 28))).called(1);
        verify(() => useCase.watchWalksSince(DateTime(2026, 10, 5))).called(1);
      },
    );

    blocTest<WalkFeedCubit, WalkFeedState>(
      '같은 주 안에서는 다시 구독하지 않는다',
      setUp: () {
        now = DateTime(2026, 10, 4, 12);
        stubWalks(() => Stream.value(Ok([walk()])));
      },
      build: () => WalkFeedCubit(useCase, FakeClock(() => now)),
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        now = DateTime(2026, 10, 4, 20);
        cubit.refreshWeekSummary();
      },
      skip: 2,
      expect: () => <WalkFeedState>[],
      verify: (_) => verify(() => useCase.watchWalksSince(any())).called(1),
    );

    blocTest<WalkFeedCubit, WalkFeedState>(
      '목록이 아직 없으면 아무것도 내지 않는다',
      build: () => WalkFeedCubit(useCase, clock),
      act: (cubit) => cubit.refreshWeekSummary(),
      expect: () => <WalkFeedState>[],
    );
  });

  group('toggleFavoritesOnly', () {
    final favorite = walk().copyWith(id: 'fav', isFavorite: true);
    final inPage = walk().copyWith(id: 'w5', isFavorite: true);
    final older = walk().copyWith(id: 'old', isFavorite: true);

    blocTest<WalkFeedCubit, WalkFeedState>(
      '켜면 지금 목록을 바로 걸러 내고, limit 을 한 페이지로 되돌려 favoritesOnly 로 다시 구독한다',
      setUp: () => stubRecent(
        (limit, favoritesOnly) => Stream.value(
          Ok(
            favoritesOnly
                ? [inPage, older]
                : [
                    for (var i = 0; i < limit; i++)
                      i == 5 ? inPage : walk().copyWith(id: 'w$i'),
                  ],
          ),
        ),
      ),
      build: () => WalkFeedCubit(useCase, clock),
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        cubit.loadMore();
        await Future<void>.delayed(Duration.zero);
        cubit.toggleFavoritesOnly();
        await Future<void>.delayed(Duration.zero);
      },
      skip: 4, // loading · 30 · 60 로딩 중 · 60
      expect: () => [
        // 깜빡임 없이 읽은 목록 중 즐겨찾기만. 새 구독 첫 값 전에는 더 읽지 않는다.
        WalkFeedState.loaded(
          walks: [inPage],
          tracker: const TrackerState.idle(),
          favoritesOnly: true,
        ),
        WalkFeedState.loaded(
          walks: [inPage, older],
          tracker: const TrackerState.idle(),
          favoritesOnly: true,
        ),
      ],
      verify: (_) {
        verifyRecent(limit: 30);
        verifyRecent(limit: 60);
        verifyRecent(limit: 30, favoritesOnly: true);
      },
    );

    blocTest<WalkFeedCubit, WalkFeedState>(
      '켠 직후 새 값 전에는 loadMore 가 아무것도 하지 않는다',
      setUp: () => stubRecent(
        (limit, favoritesOnly) => favoritesOnly
            ? const Stream.empty()
            : Stream.value(
                Ok([
                  for (var i = 0; i < limit; i++)
                    walk().copyWith(id: 'w$i', isFavorite: true),
                ]),
              ),
      ),
      build: () => WalkFeedCubit(useCase, clock),
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        cubit.toggleFavoritesOnly();
        cubit.loadMore();
        await Future<void>.delayed(Duration.zero);
      },
      skip: 2,
      expect: () => [
        isA<WalkFeedLoaded>()
            .having((s) => s.walks.length, 'walks', 30)
            .having((s) => s.hasMore, 'hasMore', isFalse)
            .having((s) => s.isLoadingMore, 'isLoadingMore', isFalse),
      ],
      verify: (_) => verifyNever(
        () => useCase.watchRecentWalks(
          limit: 60,
          favoritesOnly: any(named: 'favoritesOnly'),
        ),
      ),
    );

    blocTest<WalkFeedCubit, WalkFeedState>(
      '다시 끄면 전체를 한 페이지로 다시 구독한다',
      setUp: () => stubRecent(
        (_, favoritesOnly) =>
            Stream.value(Ok(favoritesOnly ? [favorite] : [walk(), favorite])),
      ),
      build: () => WalkFeedCubit(useCase, clock),
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        cubit.toggleFavoritesOnly();
        await Future<void>.delayed(Duration.zero);
        cubit.toggleFavoritesOnly();
        await Future<void>.delayed(Duration.zero);
      },
      // loading · 전체 · 켬(바로 거른 목록 — 새 값과 같아 한 번만) · 끔(이전 목록) · 전체
      skip: 4,
      expect: () => [
        WalkFeedState.loaded(
          walks: [walk(), favorite],
          tracker: const TrackerState.idle(),
        ),
      ],
      verify: (_) => verify(
        () => useCase.watchRecentWalks(limit: 30, favoritesOnly: false),
      ).called(2),
    );

    blocTest<WalkFeedCubit, WalkFeedState>(
      'loaded 전에는 아무것도 내지 않는다',
      build: () => WalkFeedCubit(useCase, clock),
      act: (cubit) => cubit.toggleFavoritesOnly(),
      expect: () => <WalkFeedState>[],
    );
  });

  group('페이지', () {
    List<Walk> walks(int n) =>
        List.generate(n, (i) => walk().copyWith(id: 'w$i'));

    blocTest<WalkFeedCubit, WalkFeedState>(
      '처음엔 한 페이지(30)를 구독하고, 꽉 차게 오면 hasMore',
      setUp: () => stubRecent((limit, _) => Stream.value(Ok(walks(limit)))),
      build: () => WalkFeedCubit(useCase, clock),
      act: (cubit) => cubit.start(),
      expect: () => [
        const WalkFeedState.loading(),
        WalkFeedState.loaded(
          walks: walks(30),
          tracker: const TrackerState.idle(),
          hasMore: true,
        ),
      ],
      verify: (_) {
        expect(WalkFeedCubit.pageSize, 30);
        verifyRecent(limit: 30);
      },
    );

    blocTest<WalkFeedCubit, WalkFeedState>(
      'loadMore 는 60 으로 다시 구독하고, 값이 올 때까지 isLoadingMore',
      setUp: () => stubRecent(
        (limit, _) => limit == 30
            ? Stream.value(Ok(walks(30)))
            : Stream.fromFuture(
                Future.delayed(
                  const Duration(milliseconds: 10),
                  () => Ok(walks(45)),
                ),
              ),
      ),
      build: () => WalkFeedCubit(useCase, clock),
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        cubit.loadMore();
        cubit.loadMore(); // 불러오는 중에는 무시한다
        await Future<void>.delayed(const Duration(milliseconds: 30));
      },
      skip: 2,
      expect: () => [
        WalkFeedState.loaded(
          walks: walks(30),
          tracker: const TrackerState.idle(),
          hasMore: true,
          isLoadingMore: true,
        ),
        WalkFeedState.loaded(
          walks: walks(45),
          tracker: const TrackerState.idle(),
        ),
      ],
      verify: (_) {
        verifyRecent(limit: 30);
        verifyRecent(limit: 60);
      },
    );

    blocTest<WalkFeedCubit, WalkFeedState>(
      'limit 보다 적게 오면 hasMore 가 false 고, loadMore 는 아무것도 하지 않는다',
      setUp: () => stubRecent((_, _) => Stream.value(Ok(walks(29)))),
      build: () => WalkFeedCubit(useCase, clock),
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        cubit.loadMore();
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const WalkFeedState.loading(),
        WalkFeedState.loaded(
          walks: walks(29),
          tracker: const TrackerState.idle(),
        ),
      ],
      verify: (_) => verifyRecent(limit: 30),
    );

    blocTest<WalkFeedCubit, WalkFeedState>(
      'loaded 전에는 loadMore 가 아무것도 하지 않는다',
      build: () => WalkFeedCubit(useCase, clock),
      act: (cubit) => cubit.loadMore(),
      expect: () => <WalkFeedState>[],
    );

    blocTest<WalkFeedCubit, WalkFeedState>(
      'loadMore 뒤 retry 는 limit 을 30 으로 되돌린다',
      setUp: () {
        var failed = false;
        stubRecent((limit, _) {
          if (limit == 60 && !failed) {
            failed = true;
            return Stream.value(const Err(Failure.unknown()));
          }
          return Stream.value(Ok(walks(limit)));
        });
      },
      build: () => WalkFeedCubit(useCase, clock),
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(Duration.zero);
        cubit.loadMore();
        await Future<void>.delayed(Duration.zero);
        await cubit.retry();
        await Future<void>.delayed(Duration.zero);
      },
      skip: 3, // loading · 30 · 로딩 중
      expect: () => [
        const WalkFeedState.failure(Failure.unknown()),
        const WalkFeedState.loading(),
        WalkFeedState.loaded(
          walks: walks(30),
          tracker: const TrackerState.idle(),
          hasMore: true,
        ),
      ],
      verify: (_) {
        verify(
          () => useCase.watchRecentWalks(limit: 30, favoritesOnly: false),
        ).called(2);
        verifyRecent(limit: 60);
      },
    );

    test('loadMore 뒤 이전 구독이 늦게 낸 값은 무시한다', () async {
      final first = StreamController<Result<List<Walk>>>();
      final second = StreamController<Result<List<Walk>>>();
      addTearDown(() {
        unawaited(first.close());
        unawaited(second.close());
      });
      stubRecent((limit, _) => limit == 30 ? first.stream : second.stream);
      final cubit = WalkFeedCubit(useCase, clock);
      await cubit.start();
      first.add(Ok(walks(30)));
      await Future<void>.delayed(Duration.zero);

      cubit.loadMore();
      first.add(Ok(walks(3)));
      await Future<void>.delayed(Duration.zero);

      expect(
        cubit.state,
        isA<WalkFeedLoaded>()
            .having((s) => s.walks.length, 'walks', 30)
            .having((s) => s.isLoadingMore, 'isLoadingMore', isTrue),
      );
      expect(first.hasListener, isFalse);

      second.add(Ok(walks(45)));
      await Future<void>.delayed(Duration.zero);
      expect((cubit.state as WalkFeedLoaded).walks.length, 45);
      await cubit.close();
    });

    blocTest<WalkFeedCubit, WalkFeedState>(
      '요약 스트림이 Err 를 내면 지난 요약을 둔다',
      setUp: () {
        stubWalks(() => Stream.value(Ok([walk()])));
        stubWeek(
          () => Stream.fromIterable([
            Ok([walk()]),
            const Err(Failure.unknown()),
          ]),
        );
      },
      build: () =>
          WalkFeedCubit(useCase, FakeClock.fixed(DateTime(2026, 10, 4, 12))),
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
      skip: 1,
      expect: () => [
        WalkFeedState.loaded(
          walks: [walk()],
          tracker: const TrackerState.idle(),
          weekSummary: const PeriodSummary(
            distanceMeters: 1200,
            duration: Duration(minutes: 30),
            walkCount: 1,
          ),
        ),
      ],
    );

    blocTest<WalkFeedCubit, WalkFeedState>(
      '이번 주 요약은 페이지가 아니라 since 스트림으로 센다(이번 주 31개, 페이지 30개)',
      setUp: () {
        stubRecent((limit, _) => Stream.value(Ok(walks(limit))));
        stubWeek(() => Stream.value(Ok(walks(31))));
      },
      // t0 = 2026-10-03(토) → 같은 주 일요일
      build: () =>
          WalkFeedCubit(useCase, FakeClock.fixed(DateTime(2026, 10, 4, 12))),
      act: (cubit) => cubit.start(),
      skip: 1,
      expect: () => [
        isA<WalkFeedLoaded>()
            .having((s) => s.walks.length, 'walks', 30)
            .having((s) => s.weekSummary.walkCount, 'weekCount', 31),
      ],
      verify: (_) => verify(
        () => useCase.watchWalksSince(DateTime(2026, 9, 28)),
      ).called(1),
    );

    blocTest<WalkFeedCubit, WalkFeedState>(
      '요약 스트림이 목록 뒤에 와도 loaded 의 요약을 갱신한다',
      setUp: () {
        stubWalks(() => Stream.value(Ok([walk()])));
        stubWeek(
          () => Stream.fromFuture(
            Future.delayed(
              const Duration(milliseconds: 10),
              () => Ok([walk()]),
            ),
          ),
        );
      },
      build: () =>
          WalkFeedCubit(useCase, FakeClock.fixed(DateTime(2026, 10, 4, 12))),
      act: (cubit) async {
        await cubit.start();
        await Future<void>.delayed(const Duration(milliseconds: 30));
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
          weekSummary: const PeriodSummary(
            distanceMeters: 1200,
            duration: Duration(minutes: 30),
            walkCount: 1,
          ),
        ),
      ],
    );
  });

  test('닫힌 뒤에 온 값은 상태를 내지 않고 구독을 끊는다', () async {
    final controller = StreamController<Result<List<Walk>>>();
    stubWalks(() => controller.stream);
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
    setUp(() => stubWalks(() => Stream.value(const Ok([]))));

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
