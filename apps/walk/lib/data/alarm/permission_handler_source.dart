import 'package:permission/permission.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// `permission_handler` 권한 하나를 [PermissionSource] 로 바꾼다.
class PermissionHandlerSource implements PermissionSource {
  PermissionHandlerSource(this.permission);

  final ph.Permission permission;

  @override
  Future<PermissionStatus> check() async => statusOf(await permission.status);

  @override
  Future<PermissionStatus> request() async =>
      statusOf(await permission.request());

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
