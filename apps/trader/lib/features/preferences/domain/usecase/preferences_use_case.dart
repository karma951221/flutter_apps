import 'package:injectable/injectable.dart';

import '../entity/app_language.dart';
import '../entity/app_theme_mode.dart';
import '../repository/language_repository.dart';
import '../repository/theme_repository.dart';

/// preferences feature 의 presentation 진입점 (규칙 ③).
///
/// 기기에 남는 앱 설정 — 지금은 화면 테마와 앱 언어 — 을 하나의 facade 로 묶는다.
/// 저장소는 관심사별로 [ThemeRepository] · [LanguageRepository] 로 나눠 두고
/// facade 만 합친다. `SafetyUseCase` 가 신고·차단 저장소를 묶는 방식과 같다.
abstract interface class PreferencesUseCase {
  AppThemeMode loadThemeMode();

  Future<void> saveThemeMode(AppThemeMode mode);

  AppLanguage loadLanguage();

  Future<void> saveLanguage(AppLanguage language);
}

@LazySingleton(as: PreferencesUseCase)
class DefaultPreferencesUseCase implements PreferencesUseCase {
  DefaultPreferencesUseCase(this._themeRepository, this._languageRepository);

  final ThemeRepository _themeRepository;
  final LanguageRepository _languageRepository;

  @override
  AppThemeMode loadThemeMode() => _themeRepository.loadThemeMode();

  @override
  Future<void> saveThemeMode(AppThemeMode mode) =>
      _themeRepository.saveThemeMode(mode);

  @override
  AppLanguage loadLanguage() => _languageRepository.loadLanguage();

  @override
  Future<void> saveLanguage(AppLanguage language) =>
      _languageRepository.saveLanguage(language);
}
