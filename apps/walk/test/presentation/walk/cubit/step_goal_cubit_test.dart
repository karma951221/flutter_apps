import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/domain/settings/repository/settings_repository.dart';
import 'package:walk/presentation/walk/cubit/step_goal_cubit.dart';

class _MemorySettings implements SettingsRepository {
  _MemorySettings(this.value);

  AppSettings value;

  @override
  AppSettings load() => value;

  @override
  Future<void> save(AppSettings settings) async => value = settings;
}

void main() {
  late _MemorySettings repository;

  setUp(() {
    repository = _MemorySettings(
      const AppSettings(themeMode: AppThemeMode.dark, stepGoal: 8000),
    );
  });

  test('처음 값은 저장된 목표', () {
    expect(StepGoalCubit(repository).state, 8000);
  });

  blocTest<StepGoalCubit, int>(
    'select 는 1,000 단위로 맞춰 반영하고 저장하며 다른 필드는 유지한다',
    build: () => StepGoalCubit(repository),
    act: (cubit) => cubit.select(7499),
    expect: () => [7000],
    verify: (_) {
      expect(repository.value.stepGoal, 7000);
      expect(repository.value.themeMode, AppThemeMode.dark);
    },
  );

  blocTest<StepGoalCubit, int>(
    '같은 값이면 아무것도 하지 않는다',
    build: () => StepGoalCubit(repository),
    act: (cubit) => cubit.select(8000),
    expect: () => <int>[],
  );
}
