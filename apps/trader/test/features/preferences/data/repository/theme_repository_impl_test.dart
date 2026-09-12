import 'package:daylog/features/preferences/data/datasource/preferences_theme_data_source.dart';
import 'package:daylog/features/preferences/data/repository/theme_repository_impl.dart';
import 'package:daylog/features/preferences/domain/entity/app_theme_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ThemeRepositoryImpl> createRepository(
    Map<String, Object> initialValues,
  ) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final preferences = await SharedPreferences.getInstance();
    return ThemeRepositoryImpl(PreferencesThemeDataSource(preferences));
  }

  test('저장한 값을 그대로 다시 읽는다', () async {
    final repository = await createRepository({});

    await repository.saveThemeMode(AppThemeMode.dark);
    expect(repository.loadThemeMode(), AppThemeMode.dark);

    await repository.saveThemeMode(AppThemeMode.light);
    expect(repository.loadThemeMode(), AppThemeMode.light);
  });

  test('저장된 값이 없으면 시스템이다', () async {
    final repository = await createRepository({});

    expect(repository.loadThemeMode(), AppThemeMode.system);
  });

  test('이미 저장된 값이 있으면 첫 읽기부터 그 값이다', () async {
    // 재시작 직후를 흉내낸다 — 읽기가 동기라 첫 프레임에 곧바로 쓸 수 있다.
    final repository = await createRepository({'theme_mode': 'dark'});

    expect(repository.loadThemeMode(), AppThemeMode.dark);
  });

  test('모르는 값이 저장돼 있어도 시스템으로 읽는다', () async {
    final repository = await createRepository({'theme_mode': 'sepia'});

    expect(repository.loadThemeMode(), AppThemeMode.system);
  });
}
