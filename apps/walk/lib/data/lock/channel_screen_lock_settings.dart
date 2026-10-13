import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../domain/lock/screen_lock_settings.dart';

/// `MainActivity` 의 채널로 안드로이드 화면 잠금 설정을 연다.
/// (`SET_NEW_PASSWORD`, 없으면 보안 설정)
@LazySingleton(as: ScreenLockSettings)
class ChannelScreenLockSettings implements ScreenLockSettings {
  static const _channel = MethodChannel('com.karma.walk/screen_lock');

  @override
  Future<void> open() async {
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on PlatformException {
      // 열 화면이 없다. 사용자가 설정 앱에서 직접 찾는다.
    } on MissingPluginException {
      // 안드로이드가 아닌 환경.
    }
  }
}
