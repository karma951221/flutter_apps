/// 런타임 권한 상태. 요청 API 는 앱마다 다르므로(geolocator · health)
/// 각 앱의 [PermissionSource] 가 이 값으로 바꿔 준다.
enum PermissionStatus {
  granted,
  denied,

  /// 플랫폼이 더 이상 다이얼로그를 띄우지 않는다고 알려준 상태.
  /// 알려주지 않는 플랫폼(Health Connect)은 [denied] 로 둔다.
  permanentlyDenied,
}
