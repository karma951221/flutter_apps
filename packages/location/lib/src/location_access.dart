import 'package:permission/permission.dart';

import 'geolocator_permission_source.dart';
import 'location_gateway.dart';

/// 위치를 쓰기 전에 확인한 결과.
enum LocationAccessStatus { granted, serviceDisabled, permissionDenied }

/// 위치를 쓰기 전 확인 순서: 위치 서비스 → 권한.
///
/// 권한은 [PermissionRequester] 로 세션당 한 번만 묻는다. Android 는 첫 거부 뒤에도
/// `denied` 를 돌려주므로 기억하지 않으면 시스템 다이얼로그가 계속 뜬다. 인스턴스가
/// 기억을 가지므로 앱 수명 동안 하나만 둔다(싱글턴 저장소 · 추적기의 필드).
class LocationAccess {
  LocationAccess(this._gateway)
    : permission = PermissionRequester(GeolocatorPermissionSource(_gateway));

  final LocationGateway _gateway;

  /// 설정 열기 · 다시 요청 같은 화면 동작에 쓴다.
  final PermissionRequester permission;

  /// [LocationAccessStatus.serviceDisabled] 일 때 위치 서비스를 켜러 간다.
  Future<void> openLocationSettings() => _gateway.openLocationSettings();

  /// [ensure] 와 같은 순서로 확인만 한다. 권한을 묻지 않고 세션 기억도 쓰지 않아
  /// 화면이 뜨기 전(복구) 같은 맥락 밖에서 쓴다.
  Future<LocationAccessStatus> check() async {
    if (!await _gateway.isLocationServiceEnabled()) {
      return LocationAccessStatus.serviceDisabled;
    }
    if (await permission.check() != PermissionStatus.granted) {
      return LocationAccessStatus.permissionDenied;
    }
    return LocationAccessStatus.granted;
  }

  Future<LocationAccessStatus> ensure() async {
    if (!await _gateway.isLocationServiceEnabled()) {
      return LocationAccessStatus.serviceDisabled;
    }
    if (await permission.ensure() != PermissionStatus.granted) {
      return LocationAccessStatus.permissionDenied;
    }
    return LocationAccessStatus.granted;
  }
}
