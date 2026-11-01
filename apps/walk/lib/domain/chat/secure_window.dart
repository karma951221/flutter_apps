/// 창 캡처 차단(안드로이드 FLAG_SECURE). 임시 대화가 보이는 동안만 켠다.
abstract interface class SecureWindow {
  Future<void> setSecure(bool on);
}
