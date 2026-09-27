/// 설정 탭 "앱 정보"의 버전. 구현은 `data/app_info/` (package_info_plus).
abstract interface class AppInfoSource {
  /// `1.0.0 (1)` 형식 — pubspec 의 `version: 1.0.0+1`.
  Future<String> version();
}
