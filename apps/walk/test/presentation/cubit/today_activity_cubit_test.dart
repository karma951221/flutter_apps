import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/entity/daily_activity.dart';
import 'package:walk/domain/usecase/walk_use_case.dart';
import 'package:walk/presentation/cubit/today_activity_cubit.dart';
import 'package:walk/presentation/cubit/today_activity_state.dart';

class _MockUseCase extends Mock implements WalkUseCase {}

final _today = DailyActivity(date: DateTime(2026, 9, 23), steps: 6240);

void main() {
  late _MockUseCase useCase;
  setUp(() => useCase = _MockUseCase());

  blocTest<TodayActivityCubit, TodayActivityState>(
    'load → loading · loaded',
    build: () {
      when(() => useCase.today()).thenAnswer((_) async => Ok(_today));
      return TodayActivityCubit(useCase);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const TodayActivityState.loading(),
      TodayActivityState.loaded(_today),
    ],
  );

  blocTest<TodayActivityCubit, TodayActivityState>(
    '실패 → failure',
    build: () {
      when(() => useCase.today()).thenAnswer((_) async => const Err(Failure.unknown()));
      return TodayActivityCubit(useCase);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const TodayActivityState.loading(),
      const TodayActivityState.failure(Failure.unknown()),
    ],
  );

  blocTest<TodayActivityCubit, TodayActivityState>(
    'refresh 는 loaded 를 유지한 채 새 값으로 바꾼다 (깜빡임 없음)',
    build: () {
      when(() => useCase.today()).thenAnswer((_) async => Ok(_today));
      return TodayActivityCubit(useCase);
    },
    seed: () => TodayActivityState.loaded(DailyActivity.empty(DateTime(2026, 9, 23))),
    act: (cubit) => cubit.refresh(),
    expect: () => [TodayActivityState.loaded(_today)],
  );
}
