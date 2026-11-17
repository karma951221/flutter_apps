import 'package:flutter/services.dart';
import 'package:permission/permission.dart';

/// Android 14+ `USE_FULL_SCREEN_INTENT`. `permission_handler` 에 확인 API 가 없어
/// MainActivity 의 채널로 `NotificationManager.canUseFullScreenIntent()` 를 읽는다.
class FullScreenIntentPermissionSource implements PermissionSource {
  FullScreenIntentPermissionSource([this._channel = const MethodChannel(channelName)]);

  final MethodChannel _channel;

  static const channelName = 'walk/full_screen_intent';

  @override
  Future<PermissionStatus> check() async {
    try {
      final canUse = await _channel.invokeMethod<bool>('canUse') ?? true;
      return canUse ? PermissionStatus.granted : PermissionStatus.denied;
    } on MissingPluginException {
      return PermissionStatus.granted;
    }
  }

  /// 런타임 다이얼로그가 없어 설정 화면을 여는 것뿐이다. 돌아오는 값은 연 직후 상태라
  /// 대개 아직 denied 다 — 화면이 복귀(resumed) 때 `check()` 로 다시 읽는다.
  @override
  Future<PermissionStatus> request() async {
    await openSettings();
    return check();
  }

  @override
  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on MissingPluginException {
      // 채널이 없는 플랫폼(테스트)에서는 열 화면이 없다.
    }
  }
}
