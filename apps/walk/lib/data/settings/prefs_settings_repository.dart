import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/settings/entity/app_settings.dart';
import '../../domain/settings/repository/settings_repository.dart';

@LazySingleton(as: SettingsRepository)
class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const themeModeKey = 'walk.themeMode';

  @override
  AppSettings load() {
    // getString 은 문자열이 아닌 값에서 던진다 — 첫 프레임 전 ThemeCubit 이 죽지 않게 get 으로 읽는다.
    final name = _prefs.get(themeModeKey);
    final themeMode = AppThemeMode.values.asNameMap()[name] ?? AppThemeMode.system;
    return AppSettings(themeMode: themeMode);
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _prefs.setString(themeModeKey, settings.themeMode.name);
  }
}
