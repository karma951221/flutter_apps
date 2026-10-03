import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/settings/entity/app_settings.dart';
import '../../domain/settings/repository/settings_repository.dart';
import '../../domain/walk/entity/step_goal.dart';

@LazySingleton(as: SettingsRepository)
class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const themeModeKey = 'walk.themeMode';
  static const stepGoalKey = 'walk.stepGoal';
  static const goalCelebratedOnKey = 'walk.goalCelebratedOn';

  @override
  AppSettings load() {
    // getString 은 문자열이 아닌 값에서 던진다 — 첫 프레임 전 ThemeCubit 이 죽지 않게 get 으로 읽는다.
    final name = _prefs.get(themeModeKey);
    final themeMode =
        AppThemeMode.values.asNameMap()[name] ?? AppThemeMode.system;
    final goal = _prefs.get(stepGoalKey);
    final celebrated = _prefs.get(goalCelebratedOnKey);
    return AppSettings(
      themeMode: themeMode,
      stepGoal: goal is int ? StepGoal.clamp(goal) : StepGoal.defaultSteps,
      goalCelebratedOn: celebrated is String
          ? DateTime.tryParse(celebrated)
          : null,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _prefs.setString(themeModeKey, settings.themeMode.name);
    await _prefs.setInt(stepGoalKey, settings.stepGoal);
    final celebrated = settings.goalCelebratedOn;
    if (celebrated == null) {
      await _prefs.remove(goalCelebratedOnKey);
    } else {
      // 날짜만 저장한다(yyyy-MM-dd). 읽으면 로컬 자정이 된다.
      await _prefs.setString(
        goalCelebratedOnKey,
        celebrated.toIso8601String().substring(0, 10),
      );
    }
  }
}
