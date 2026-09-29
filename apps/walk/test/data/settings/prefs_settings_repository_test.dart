import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/settings/prefs_settings_repository.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';

void main() {
  test('저장한 적이 없으면 시스템 테마', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = PrefsSettingsRepository(await SharedPreferences.getInstance());

    expect(repository.load(), const AppSettings());
    expect(repository.load().themeMode, AppThemeMode.system);
  });

  test('저장한 테마를 읽는다', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await PrefsSettingsRepository(prefs).save(const AppSettings(themeMode: AppThemeMode.dark));

    expect(PrefsSettingsRepository(prefs).load().themeMode, AppThemeMode.dark);
  });

  test('모르는 값이면 시스템 테마', () async {
    SharedPreferences.setMockInitialValues({PrefsSettingsRepository.themeModeKey: 'sepia'});
    final repository = PrefsSettingsRepository(await SharedPreferences.getInstance());

    expect(repository.load().themeMode, AppThemeMode.system);
  });

  test('문자열이 아닌 값이 저장돼 있어도 시스템 테마', () async {
    SharedPreferences.setMockInitialValues({PrefsSettingsRepository.themeModeKey: 2});
    final repository = PrefsSettingsRepository(await SharedPreferences.getInstance());

    expect(repository.load().themeMode, AppThemeMode.system);
  });
}
