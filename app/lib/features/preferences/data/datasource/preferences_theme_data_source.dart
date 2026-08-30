import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_data_source.dart';

/// `SharedPreferences` 구현.
///
/// `getInstance()` 이후 값은 메모리 캐시라 읽기가 동기다. 그래서 cubit 이
/// 생성자에서 곧바로 읽을 수 있고 첫 프레임 깜빡임이 없다.
@LazySingleton(as: ThemeDataSource)
class PreferencesThemeDataSource implements ThemeDataSource {
  PreferencesThemeDataSource(this._preferences);

  static const _key = 'theme_mode';

  final SharedPreferences _preferences;

  @override
  String? readThemeCode() => _preferences.getString(_key);

  @override
  Future<void> writeThemeCode(String code) =>
      _preferences.setString(_key, code);
}
