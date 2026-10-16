import 'package:permission/permission.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// 알림 권한(Android 13+ `POST_NOTIFICATIONS`)을 [PermissionSource] 로 바꾼다.
/// Android 12 이하 · iOS 에서는 permission_handler 가 허용으로 답한다.
class NotificationPermissionSource implements PermissionSource {
  const NotificationPermissionSource();

  static const _permission = ph.Permission.notification;

  @override
  Future<PermissionStatus> check() async => statusOf(await _permission.status);

  @override
  Future<PermissionStatus> request() async =>
      statusOf(await _permission.request());

  @override
  Future<void> openSettings() async {
    await ph.openAppSettings();
  }

  static PermissionStatus statusOf(ph.PermissionStatus status) =>
      switch (status) {
        ph.PermissionStatus.granted ||
        ph.PermissionStatus.limited ||
        ph.PermissionStatus.provisional => PermissionStatus.granted,
        ph.PermissionStatus.permanentlyDenied ||
        ph.PermissionStatus.restricted => PermissionStatus.permanentlyDenied,
        ph.PermissionStatus.denied => PermissionStatus.denied,
      };
}
