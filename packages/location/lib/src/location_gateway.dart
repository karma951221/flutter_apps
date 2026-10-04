import 'package:geolocator/geolocator.dart';

/// geolocator 정적 API 를 감싸 테스트가 대체할 수 있게 한다.
///
/// 정확도 · 갱신 간격 같은 설정은 앱마다 달라서 호출하는 쪽이 넘긴다.
abstract interface class LocationGateway {
  Future<bool> isLocationServiceEnabled();

  Future<LocationPermission> checkPermission();

  Future<LocationPermission> requestPermission();

  Future<bool> openAppSettings();

  Future<Position> getCurrentPosition({
    required LocationAccuracy accuracy,
    required Duration timeout,
  });

  Stream<Position> positionStream(LocationSettings settings);

  /// 두 좌표 사이의 거리(미터).
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  );
}

/// 상태가 없어 앱이 DI 에 하나만 등록해 쓴다.
class GeolocatorGateway implements LocationGateway {
  const GeolocatorGateway();

  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<Position> getCurrentPosition({
    required LocationAccuracy accuracy,
    required Duration timeout,
  }) => Geolocator.getCurrentPosition(
    locationSettings: LocationSettings(accuracy: accuracy, timeLimit: timeout),
  );

  @override
  Stream<Position> positionStream(LocationSettings settings) =>
      Geolocator.getPositionStream(locationSettings: settings);

  @override
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) => Geolocator.distanceBetween(
    startLatitude,
    startLongitude,
    endLatitude,
    endLongitude,
  );
}
