import 'permission_status.dart';

/// 권한 하나를 확인 · 요청하는 플랫폼 경계. 앱이 플러그인으로 구현한다.
abstract interface class PermissionSource {
  Future<PermissionStatus> check();

  Future<PermissionStatus> request();

  Future<void> openSettings();
}
