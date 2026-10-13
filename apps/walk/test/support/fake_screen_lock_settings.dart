import 'package:walk/domain/lock/screen_lock_settings.dart';

/// 폰 화면 잠금 설정 열기 대역. 열린 횟수만 센다.
class FakeScreenLockSettings implements ScreenLockSettings {
  int opened = 0;

  @override
  Future<void> open() async => opened++;
}
