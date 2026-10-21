import 'package:health/health.dart';
import 'package:permission/permission.dart';

import 'health_gateway.dart';

/// 걸음 권한 기준. Health Connect 는 두 번 거부하면 다이얼로그를 조용히 생략할 뿐
/// 구분해 주지 않으므로 [PermissionStatus.permanentlyDenied] 는 돌려주지 않는다
/// (permission 설계 §2) — 화면은 `declinedThisSession` 으로 "설정 열기"를 보인다.
class HealthPermissionSource implements PermissionSource {
  HealthPermissionSource(this._gateway);

  final HealthGateway _gateway;

  static const readTypes = [HealthDataType.STEPS];

  @override
  Future<PermissionStatus> check() async =>
      await _gateway.hasPermission(HealthDataType.STEPS)
      ? PermissionStatus.granted
      : PermissionStatus.denied;

  @override
  Future<PermissionStatus> request() async {
    await _gateway.requestPermissions(readTypes);
    final status = await check();
    // 걸음을 허용한 사람에게만 30일 이전 기록을 묻는다. 거부하면 그 이전 기간이 0으로 보일 뿐이다.
    if (status == PermissionStatus.granted) {
      await _gateway.requestHistoryPermission();
    }
    return status;
  }

  @override
  Future<void> openSettings() => _gateway.openHealthConnectSettings();
}
