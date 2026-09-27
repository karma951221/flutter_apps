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
    final name = _prefs.getString(themeModeKey);
    final themeMode = AppThemeMode.values.asNameMap()[name] ?? AppThemeMode.system;
    return AppSettings(themeMode: themeMode);
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _prefs.setString(themeModeKey, settings.themeMode.name);
  }
}
