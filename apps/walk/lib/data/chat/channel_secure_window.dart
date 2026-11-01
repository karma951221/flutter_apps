import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../domain/chat/secure_window.dart';

/// `MainActivity` 의 채널로 창 캡처 차단(FLAG_SECURE)을 켜고 끈다.
/// 안드로이드가 아니면(MissingPluginException) · PlatformException 이면 조용히 넘어간다.
@LazySingleton(as: SecureWindow)
class ChannelSecureWindow implements SecureWindow {
  static const channel = MethodChannel('com.karma.walk/secure_window');

  @override
  Future<void> setSecure(bool on) async {
    try {
      await channel.invokeMethod<void>('setSecure', on);
    } on PlatformException {
      // 창 플래그를 바꾸지 못했다. 대화는 그대로 쓸 수 있다.
    } on MissingPluginException {
      // 안드로이드가 아닌 환경.
    }
  }
}
