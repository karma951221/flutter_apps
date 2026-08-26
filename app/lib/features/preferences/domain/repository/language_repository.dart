import '../entity/app_language.dart';

/// 앱 언어 선택의 저장소.
///
/// `ThemeRepository` 와 같은 이유로 `Result` 도 error handler mixin 도 쓰지
/// 않는다 — 읽기는 메모리 캐시라 실패하지 않고, 쓰기 실패는 사용자에게 보고하지
/// 않는다.
///
/// 테마와 언어를 한 저장소로 합치지 않는다. facade 만 `PreferencesUseCase` 로
/// 통합하고 저장소는 관심사별로 둔다 (규칙 ③).
abstract interface class LanguageRepository {
  /// 저장된 언어. 값이 없거나 모르는 값이면 [AppLanguage.system].
  ///
  /// 동기다 — 첫 프레임에 곧바로 읽어야 기기 언어로 떴다가 고른 언어로 바뀌는
  /// 깜빡임이 없다.
  AppLanguage loadLanguage();

  Future<void> saveLanguage(AppLanguage language);
}
