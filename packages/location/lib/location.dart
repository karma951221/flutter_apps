/// geolocator 래퍼와 위치 접근 확인 흐름. 앱은 geolocator 를 직접 의존하지 않고
/// 여기서 필요한 타입만 받는다.
library;

export 'package:geolocator/geolocator.dart'
    show
        ActivityType,
        AndroidSettings,
        AppleSettings,
        ForegroundNotificationConfig,
        LocationAccuracy,
        LocationPermission,
        LocationServiceDisabledException,
        PermissionDeniedException,
        LocationSettings,
        Position;

export 'src/geolocator_permission_source.dart';
export 'src/location_access.dart';
export 'src/location_gateway.dart';
