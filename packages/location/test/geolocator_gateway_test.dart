import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:location/location.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

final _position = Position(
  latitude: 37.5,
  longitude: 127,
  timestamp: DateTime.utc(2026, 10, 4),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

class _FakePlatform extends GeolocatorPlatform with MockPlatformInterfaceMixin {
  LocationSettings? currentSettings;
  LocationSettings? streamSettings;
  var openedSettings = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.denied;

  @override
  Future<bool> openAppSettings() async {
    openedSettings++;
    return true;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    currentSettings = locationSettings;
    return _position;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    streamSettings = locationSettings;
    return Stream.value(_position);
  }
}

void main() {
  late _FakePlatform platform;
  const gateway = GeolocatorGateway();

  setUp(() {
    platform = _FakePlatform();
    GeolocatorPlatform.instance = platform;
  });

  test('권한 · 서비스 · 설정 열기를 플랫폼에 위임한다', () async {
    expect(await gateway.isLocationServiceEnabled(), isTrue);
    expect(await gateway.checkPermission(), LocationPermission.whileInUse);
    expect(await gateway.requestPermission(), LocationPermission.denied);
    expect(await gateway.openAppSettings(), isTrue);
    expect(platform.openedSettings, 1);
  });

  test('현재 위치는 넘긴 정확도와 제한 시간으로 요청한다', () async {
    final position = await gateway.getCurrentPosition(
      accuracy: LocationAccuracy.high,
      timeout: const Duration(seconds: 5),
    );

    expect(position, _position);
    expect(platform.currentSettings?.accuracy, LocationAccuracy.high);
    expect(platform.currentSettings?.timeLimit, const Duration(seconds: 5));
  });

  test('위치 스트림은 앱이 만든 설정을 그대로 넘긴다', () async {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 3,
    );

    expect(await gateway.positionStream(settings).first, _position);
    expect(platform.streamSettings, same(settings));
  });

  test('거리는 (시작 위도, 시작 경도, 끝 위도, 끝 경도) 순서로 미터를 준다', () {
    expect(gateway.distanceBetween(37.5, 127, 37.5, 127), 0);
    // 위도 0.001도 ≈ 111 m
    expect(gateway.distanceBetween(37.5, 127, 37.501, 127), closeTo(111, 1));
  });
}
