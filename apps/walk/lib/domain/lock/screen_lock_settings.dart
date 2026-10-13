/// 폰의 화면 잠금(PIN · 패턴 · 비밀번호) 설정 화면을 연다.
abstract interface class ScreenLockSettings {
  /// 열 수 없으면 조용히 끝난다 — 사용자가 직접 설정 앱으로 가면 된다.
  Future<void> open();
}
