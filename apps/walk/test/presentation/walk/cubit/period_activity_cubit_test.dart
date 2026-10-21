import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/walk/entity/activity_period.dart';
import 'package:walk/domain/walk/entity/period_kind.dart';
import 'package:walk/domain/walk/usecase/walk_use_case.dart';
import 'package:walk/presentation/walk/cubit/period_activity_cubit.dart';
import 'package:walk/presentation/walk/cubit/period_activity_state.dart';

class _MockUseCase extends Mock implements WalkUseCase {}

ActivityPeriod _period(int offset) => ActivityPeriod(
  kind: PeriodKind.week,
  start: DateTime(2026, 9, 21 + 7 * offset),
  end: DateTime(2026, 9, 27 + 7 * offset),
  today: DateTime(2026, 9, 23),
  days: const [],
);

void main() {
  late _MockUseCase useCase;

  setUpAll(() => registerFallbackValue(PeriodKind.week));
  setUp(() {
    useCase = _MockUseCase();
    when(
      () => useCase.period(PeriodKind.week, any()),
    ).thenAnswer((i) async => Ok(_period(i.positionalArguments[1] as int)));
  });

  blocTest<PeriodActivityCubit, PeriodActivityState>(
    'load 는 현재 기간(offset 0)',
    build: () => PeriodActivityCubit(useCase, PeriodKind.week),
    act: (cubit) => cubit.load(),
    expect: () => [
      const PeriodActivityState.loading(0),
      PeriodActivityState.loaded(0, _period(0)),
    ],
  );

  blocTest<PeriodActivityCubit, PeriodActivityState>(
    'previous 는 offset 을 하나 줄인다',
    build: () => PeriodActivityCubit(useCase, PeriodKind.week),
    seed: () => PeriodActivityState.loaded(0, _period(0)),
    act: (cubit) => cubit.previous(),
    expect: () => [
      const PeriodActivityState.loading(-1),
      PeriodActivityState.loaded(-1, _period(-1)),
    ],
  );

  blocTest<PeriodActivityCubit, PeriodActivityState>(
    '현재 기간에서 next 는 아무것도 하지 않는다',
    build: () => PeriodActivityCubit(useCase, PeriodKind.week),
    seed: () => PeriodActivityState.loaded(0, _period(0)),
    act: (cubit) => cubit.next(),
    expect: () => <PeriodActivityState>[],
  );

  blocTest<PeriodActivityCubit, PeriodActivityState>(
    'refresh 는 같은 offset 을 loading 없이 다시 읽는다',
    build: () => PeriodActivityCubit(useCase, PeriodKind.week),
    seed: () => PeriodActivityState.loaded(-2, _period(0)),
    act: (cubit) => cubit.refresh(),
    expect: () => [PeriodActivityState.loaded(-2, _period(-2))],
  );

  blocTest<PeriodActivityCubit, PeriodActivityState>(
    '늦게 온 이전 요청 응답은 버린다',
    build: () {
      final slow = Completer<Result<ActivityPeriod>>();
      when(
        () => useCase.period(PeriodKind.week, 0),
      ).thenAnswer((_) => slow.future);
      addTearDown(() => slow.complete(Ok(_period(0))));
      return PeriodActivityCubit(useCase, PeriodKind.week);
    },
    act: (cubit) async {
      unawaited(cubit.load()); // offset 0 — 끝나지 않음
      await cubit.previous(); // offset -1
    },
    expect: () => [
      const PeriodActivityState.loading(0),
      const PeriodActivityState.loading(-1),
      PeriodActivityState.loaded(-1, _period(-1)),
    ],
  );

  blocTest<PeriodActivityCubit, PeriodActivityState>(
    '실패해도 offset 을 지킨다',
    build: () {
      when(
        () => useCase.period(PeriodKind.week, -1),
      ).thenAnswer((_) async => const Err(Failure.unknown()));
      return PeriodActivityCubit(useCase, PeriodKind.week);
    },
    seed: () => PeriodActivityState.loaded(0, _period(0)),
    act: (cubit) => cubit.previous(),
    expect: () => [
      const PeriodActivityState.loading(-1),
      const PeriodActivityState.failure(-1, Failure.unknown()),
    ],
  );
}
