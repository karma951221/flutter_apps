import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/alarm/entity/alarm_pause.dart';
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
  static const holidayReminderKey = 'walk.holidayReminder';

  /// 쉬는 기간의 시작 · 끝 날(yyyy-MM-dd). 둘 다 있어야 쉰다.
  static const pauseFromKey = 'walk.pauseFrom';
  static const pauseUntilKey = 'walk.pauseUntil';

  @override
  AppSettings load() {
    // getString 은 문자열이 아닌 값에서 던진다 — 첫 프레임 전 ThemeCubit 이 죽지 않게 get 으로 읽는다.
    final name = _prefs.get(themeModeKey);
    final themeMode =
        AppThemeMode.values.asNameMap()[name] ?? AppThemeMode.system;
    final goal = _prefs.get(stepGoalKey);
    final celebrated = _prefs.get(goalCelebratedOnKey);
    final holidayReminder = _prefs.get(holidayReminderKey);
    return AppSettings(
      themeMode: themeMode,
      stepGoal: goal is int ? StepGoal.clamp(goal) : StepGoal.defaultSteps,
      goalCelebratedOn: celebrated is String
          ? DateTime.tryParse(celebrated)
          : null,
      holidayReminder: holidayReminder is bool ? holidayReminder : true,
      pause: _pause(),
    );
  }

  AlarmPause? _pause() {
    final from = _date(_prefs.get(pauseFromKey));
    final until = _date(_prefs.get(pauseUntilKey));
    return from == null || until == null
        ? null
        : AlarmPause(from: from, until: until);
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  /// 날짜만 저장한다(yyyy-MM-dd). 읽으면 로컬 자정이 된다.
  static String _day(DateTime date) => date.toIso8601String().substring(0, 10);

  @override
  Future<void> save(AppSettings settings) async {
    final celebrated = settings.goalCelebratedOn;
    final pause = settings.pause;
    // 모든 키 쓰기를 await 전에 시작한다 — SharedPreferences 는 캐시를 동기로 바꾸므로
    // 저장 도중 다른 쪽이 load() 해도 반쯤 쓴 스냅샷(새 테마 + 옛 목표)을 읽지 않는다.
    await Future.wait([
      _prefs.setString(themeModeKey, settings.themeMode.name),
      _prefs.setInt(stepGoalKey, settings.stepGoal),
      _prefs.setBool(holidayReminderKey, settings.holidayReminder),
      if (celebrated == null)
        _prefs.remove(goalCelebratedOnKey)
      else
        _prefs.setString(goalCelebratedOnKey, _day(celebrated)),
      if (pause == null) ...[
        _prefs.remove(pauseFromKey),
        _prefs.remove(pauseUntilKey),
      ] else ...[
        _prefs.setString(pauseFromKey, _day(pause.from)),
        _prefs.setString(pauseUntilKey, _day(pause.until)),
      ],
    ]);
  }
}
