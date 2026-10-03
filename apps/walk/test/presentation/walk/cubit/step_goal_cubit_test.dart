import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/settings/prefs_settings_repository.dart';
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

  test('목표를 바꾸자마자 축하일을 저장해도 새 목표가 남는다(실제 SharedPreferences)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PrefsSettingsRepository(
      await SharedPreferences.getInstance(),
    );
    final cubit = StepGoalCubit(prefs);
    addTearDown(cubit.close);
    // 걷기 탭이 목표 변경을 듣고 축하일을 읽고-고쳐-쓰는 것과 같다.
    final saves = <Future<void>>[];
    final sub = cubit.stream.listen((_) {
      saves.add(
        prefs.save(
          prefs.load().copyWith(goalCelebratedOn: DateTime(2026, 10, 3)),
        ),
      );
    });
    addTearDown(sub.cancel);

    await cubit.select(6000);
    await Future.wait(saves);

    expect(cubit.state, 6000);
    expect(prefs.load().stepGoal, 6000);
    expect(prefs.load().goalCelebratedOn, DateTime(2026, 10, 3));
  });
}
