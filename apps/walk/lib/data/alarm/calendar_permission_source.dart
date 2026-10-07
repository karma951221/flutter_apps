import 'package:flutter/services.dart';
import 'package:permission/permission.dart';

/// 폰 캘린더 읽기 권한(`READ_CALENDAR`) 하나. `permission_handler` 의 캘린더 권한은 안드로이드에서
/// READ + WRITE 를 함께 요구해(이 앱 매니페스트엔 READ 만 있다) 대화상자 없이 거부되므로,
/// MainActivity 의 `CalendarPermissionChannel` 로 읽기만 확인 · 요청한다.
class CalendarPermissionSource implements PermissionSource {
  CalendarPermissionSource([this._channel = const MethodChannel(channelName)]);

  final MethodChannel _channel;

  static const channelName = 'walk/calendar_permission';

  @override
  Future<PermissionStatus> check() => _status('check');

  @override
  Future<PermissionStatus> request() => _status('request');

  @override
  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on MissingPluginException {
      // 채널이 없는 플랫폼(테스트)에서는 열 화면이 없다.
    }
  }

  /// 채널이 없으면(테스트 · 헤드리스 엔진) 읽을 수 없으니 거부로 본다.
  Future<PermissionStatus> _status(String method) async {
    try {
      return switch (await _channel.invokeMethod<String>(method)) {
        'granted' => PermissionStatus.granted,
        'permanentlyDenied' => PermissionStatus.permanentlyDenied,
        _ => PermissionStatus.denied,
      };
    } on MissingPluginException {
      return PermissionStatus.denied;
    }
  }
}
