import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/domain/stats/entity/stats_period.dart';
import 'package:pawlog/domain/walk/entity/walk.dart';
import 'package:pawlog/presentation/stats/cubit/stats_cubit.dart';
import 'package:pawlog/presentation/stats/cubit/stats_state.dart';

import '../../../support/fakes.dart';
import '../../../support/mock_walk_use_case.dart';

Walk _walk(String id, DateTime startedAt, {double meters = 1000}) => Walk(
  id: id,
  startedAt: startedAt,
  endedAt: startedAt.add(const Duration(minutes: 30)),
  duration: const Duration(minutes: 30),
  distanceMeters: meters,
  dogs: [dog('1')],
  photos: const [],
  previewPoints: const [],
  createdAt: startedAt,
  updatedAt: startedAt,
);

Matcher _loaded({
  int? offset,
  bool? canShowPrevious,
  bool? canShowNext,
  bool? isEmpty,
  StatsPeriod? period,
  int? walkCount,
}) {
  var matcher = isA<StatsLoaded>();
  if (offset != null) {
    matcher = matcher.having((s) => s.offset, 'offset', offset);
  }
  if (canShowPrevious != null) {
    matcher = matcher.having(
      (s) => s.canShowPrevious,
      'canShowPrevious',
      canShowPrevious,
    );
  }
  if (canShowNext != null) {
    matcher = matcher.having((s) => s.canShowNext, 'canShowNext', canShowNext);
  }
  if (isEmpty != null) {
    matcher = matcher.having((s) => s.isEmpty, 'isEmpty', isEmpty);
  }
  if (period != null) {
    matcher = matcher.having((s) => s.stats.period, 'period', period);
  }
  if (walkCount != null) {
    matcher = matcher.having(
      (s) => s.stats.summary.walkCount,
      'walkCount',
      walkCount,
    );
  }
  return matcher;
}

void main() {
  late MockWalkUseCase useCase;
  late StreamController<Result<List<Walk>>> walks;
  late DateTime now;

  final today = _walk('b', DateTime(2026, 10, 16, 8));
  final twoWeeksAgo = _walk('a', DateTime(2026, 9, 30, 8)); // 9-28 주

  setUp(() {
    useCase = MockWalkUseCase();
    walks = StreamController<Result<List<Walk>>>();
    now = DateTime(2026, 10, 16, 15);
    when(() => useCase.watchWalks()).thenAnswer((_) => walks.stream);
  });
  tearDown(() => walks.close());

  StatsCubit build() => StatsCubit(useCase, FakeClock(() => now));

  blocTest<StatsCubit, StatsState>(
    '첫 값이 오면 이번 주로 loaded, 다음은 비활성',
    build: build,
    act: (cubit) async {
      await cubit.start();
      walks.add(Ok([today, twoWeeksAgo]));
    },
    expect: () => [
      const StatsState.loading(),
      _loaded(
        offset: 0,
        canShowPrevious: true,
        canShowNext: false,
        isEmpty: false,
        walkCount: 1,
      ),
    ],
  );

  blocTest<StatsCubit, StatsState>(
    '이전은 가장 오래된 산책이 든 주에서 멈추고, 다음은 지금에서 멈춘다',
    build: build,
    act: (cubit) async {
      await cubit.start();
      walks.add(Ok([today, twoWeeksAgo]));
      await Future<void>.delayed(Duration.zero);
      cubit
        ..showPrevious()
        ..showPrevious()
        ..showPrevious() // 더는 못 간다 — 같은 상태라 내지 않는다
        ..showNext()
        ..showNext()
        ..showNext(); // 더는 못 간다
    },
    expect: () => [
      const StatsState.loading(),
      _loaded(offset: 0),
      _loaded(offset: -1, canShowPrevious: true, canShowNext: true),
      _loaded(
        offset: -2,
        canShowPrevious: false,
        canShowNext: true,
        walkCount: 1,
      ),
      _loaded(offset: -1),
      _loaded(offset: 0, canShowNext: false),
    ],
  );

  blocTest<StatsCubit, StatsState>(
    '월로 바꾸면 offset 0 으로 돌아온다',
    build: build,
    act: (cubit) async {
      await cubit.start();
      walks.add(Ok([today, twoWeeksAgo]));
      await Future<void>.delayed(Duration.zero);
      cubit
        ..showPrevious()
        ..selectPeriod(StatsPeriod.month);
    },
    expect: () => [
      const StatsState.loading(),
      _loaded(offset: 0, period: StatsPeriod.week),
      _loaded(offset: -1, period: StatsPeriod.week),
      _loaded(offset: 0, period: StatsPeriod.month, canShowPrevious: true),
    ],
  );

  blocTest<StatsCubit, StatsState>(
    '보던 과거 기간보다 오래된 산책이 지워지면 남은 가장 오래된 기간으로 끌어올린다',
    build: build,
    act: (cubit) async {
      await cubit.start();
      walks.add(Ok([today, twoWeeksAgo]));
      await Future<void>.delayed(Duration.zero);
      cubit
        ..showPrevious()
        ..showPrevious();
      walks.add(Ok([today]));
    },
    expect: () => [
      const StatsState.loading(),
      _loaded(offset: 0),
      _loaded(offset: -1),
      _loaded(offset: -2),
      _loaded(offset: 0, canShowPrevious: false, canShowNext: false),
    ],
  );

  blocTest<StatsCubit, StatsState>(
    '화면을 연 채 주가 바뀌면 다음 스트림 값에서 새 주로 계산한다',
    build: build,
    act: (cubit) async {
      await cubit.start();
      walks.add(Ok([today]));
      await Future<void>.delayed(Duration.zero);
      now = DateTime(2026, 10, 19, 0, 1); // 다음 주 월요일
      walks.add(Ok([today]));
    },
    expect: () => [
      const StatsState.loading(),
      _loaded(offset: 0, walkCount: 1),
      _loaded(offset: 0, walkCount: 0, canShowPrevious: true),
    ],
  );

  blocTest<StatsCubit, StatsState>(
    '첫 값 전의 기간 이동은 무시한다',
    build: build,
    act: (cubit) async {
      await cubit.start();
      cubit
        ..showPrevious()
        ..selectPeriod(StatsPeriod.month);
      walks.add(Ok([today]));
    },
    expect: () => [
      const StatsState.loading(),
      _loaded(offset: 0, period: StatsPeriod.week),
    ],
  );

  blocTest<StatsCubit, StatsState>(
    '산책이 없으면 isEmpty, 앞뒤 모두 비활성',
    build: build,
    act: (cubit) async {
      await cubit.start();
      walks.add(const Ok([]));
    },
    expect: () => [
      const StatsState.loading(),
      _loaded(isEmpty: true, canShowPrevious: false, canShowNext: false),
    ],
  );

  blocTest<StatsCubit, StatsState>(
    '스트림 오류는 failure, retry 는 다시 구독한다',
    build: build,
    act: (cubit) async {
      await cubit.start();
      walks.add(const Err(Failure.unknown()));
      await Future<void>.delayed(Duration.zero);
      await walks.close();
      walks = StreamController<Result<List<Walk>>>();
      await cubit.retry();
      walks.add(Ok([today]));
    },
    expect: () => [
      const StatsState.loading(),
      isA<StatsFailure>(),
      const StatsState.loading(),
      _loaded(walkCount: 1),
    ],
  );
}
