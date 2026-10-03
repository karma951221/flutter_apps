import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/settings/prefs_settings_repository.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/domain/walk/entity/step_goal.dart';

void main() {
  test('저장한 적이 없으면 시스템 테마', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = PrefsSettingsRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.load(), const AppSettings());
    expect(repository.load().themeMode, AppThemeMode.system);
  });

  test('저장한 테마를 읽는다', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await PrefsSettingsRepository(
      prefs,
    ).save(const AppSettings(themeMode: AppThemeMode.dark));

    expect(PrefsSettingsRepository(prefs).load().themeMode, AppThemeMode.dark);
  });

  test('모르는 값이면 시스템 테마', () async {
    SharedPreferences.setMockInitialValues({
      PrefsSettingsRepository.themeModeKey: 'sepia',
    });
    final repository = PrefsSettingsRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.load().themeMode, AppThemeMode.system);
  });

  test('문자열이 아닌 값이 저장돼 있어도 시스템 테마', () async {
    SharedPreferences.setMockInitialValues({
      PrefsSettingsRepository.themeModeKey: 2,
    });
    final repository = PrefsSettingsRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.load().themeMode, AppThemeMode.system);
  });

  group('하루 목표', () {
    late PrefsSettingsRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = PrefsSettingsRepository(await SharedPreferences.getInstance());
    });

    test('목표 · 축하일 왕복', () async {
      await repo.save(
        AppSettings(stepGoal: 8000, goalCelebratedOn: DateTime(2026, 10, 3)),
      );
      final s = repo.load();
      expect(s.stepGoal, 8000);
      expect(s.goalCelebratedOn, DateTime(2026, 10, 3));
    });

    test('저장값이 없으면 기본 목표 · 축하일 없음', () {
      expect(repo.load().stepGoal, StepGoal.defaultSteps);
      expect(repo.load().goalCelebratedOn, isNull);
    });

    test('깨진 타입 · 범위 밖은 기본/clamp', () async {
      SharedPreferences.setMockInitialValues({
        PrefsSettingsRepository.stepGoalKey: 'x',
        PrefsSettingsRepository.goalCelebratedOnKey: 42,
      });
      final broken = PrefsSettingsRepository(
        await SharedPreferences.getInstance(),
      );
      expect(broken.load().stepGoal, StepGoal.defaultSteps);
      expect(broken.load().goalCelebratedOn, isNull);

      SharedPreferences.setMockInitialValues({
        PrefsSettingsRepository.stepGoalKey: 99999,
      });
      final big = PrefsSettingsRepository(
        await SharedPreferences.getInstance(),
      );
      expect(big.load().stepGoal, StepGoal.max);
    });

    test('축하일 null 저장은 키를 지운다', () async {
      await repo.save(AppSettings(goalCelebratedOn: DateTime(2026, 10, 3)));
      await repo.save(const AppSettings());
      expect(repo.load().goalCelebratedOn, isNull);
    });
  });
}
