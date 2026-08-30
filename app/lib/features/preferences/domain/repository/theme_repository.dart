import '../entity/app_theme_mode.dart';

/// 화면 테마 선택의 저장소.
///
/// `Result` 를 쓰지 않는다. 읽기는 메모리 캐시라 실패하지 않고, 쓰기 실패는
/// 사용자에게 보고하지 않기로 했다(계획서). 네트워크도 권한 경계도 없어
/// Supabase 예외가 발생할 수 없는 경로이므로 error handler mixin 도 없다.
abstract interface class ThemeRepository {
  /// 저장된 테마. 값이 없거나 모르는 값이면 [AppThemeMode.system].
  ///
  /// 동기다 — 첫 프레임에 곧바로 읽어야 라이트로 떴다가 다크로 바뀌는 깜빡임이
  /// 없다.
  AppThemeMode loadThemeMode();

  Future<void> saveThemeMode(AppThemeMode mode);
}
