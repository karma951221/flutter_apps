/// 사용자가 고른 앱 언어.
///
/// Flutter 의 `Locale` 을 쓰지 않는다 — domain 이 material·widgets 에 묶이면 규칙
/// ⑤ 가 깨진다. `Locale` 로의 매핑은 presentation 이 갖는다 ([AppThemeMode] 와
/// 같은 결).
///
/// [code] 는 기기에 저장되는 문자열이다.
enum AppLanguage {
  system('system'),
  korean('ko'),
  english('en'),
  japanese('ja');

  const AppLanguage(this.code);

  final String code;

  /// 모르는 코드와 없는 값은 [AppLanguage.system] 이다.
  ///
  /// 지원 언어가 늘어난 버전에서 되돌아오거나 저장이 깨져도 앱이 죽지 않고,
  /// "저장된 값이 없으면 기기 언어를 따른다"는 기본값과 같은 결과가 된다.
  static AppLanguage fromCode(String? code) {
    if (code == null) return AppLanguage.system;
    for (final language in values) {
      if (language.code == code) return language;
    }
    return AppLanguage.system;
  }
}
