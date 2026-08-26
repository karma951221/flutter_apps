/// 사용자가 고른 화면 테마.
///
/// Flutter 의 `ThemeMode` 를 쓰지 않는다 — domain 이 material 에 묶이면 규칙 ⑤
/// 가 깨진다. `ThemeMode` 로의 매핑은 presentation 이 갖는다.
///
/// [code] 는 기기에 저장되는 문자열이다. `ReactionType.code` 와 같은 방식이다.
enum AppThemeMode {
  system('system', '시스템 설정'),
  light('light', '라이트'),
  dark('dark', '다크');

  const AppThemeMode(this.code, this.label);

  final String code;

  /// 설정 화면이 그대로 쓰는 표시 이름.
  final String label;

  /// 모르는 코드와 없는 값은 [AppThemeMode.system] 이다.
  ///
  /// 선택지가 늘어난 버전에서 되돌아오거나 저장이 깨져도 앱이 죽지 않고,
  /// "저장된 값이 없으면 OS 를 따른다"는 기본값과 같은 결과가 된다.
  static AppThemeMode fromCode(String? code) {
    if (code == null) return AppThemeMode.system;
    for (final mode in values) {
      if (mode.code == code) return mode;
    }
    return AppThemeMode.system;
  }
}
