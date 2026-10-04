import 'package:flutter_test/flutter_test.dart';
import 'package:location/location.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';

class _MockLocationGateway extends Mock implements LocationGateway {}

void main() {
  late _MockLocationGateway gateway;
  late GeolocatorPermissionSource source;

  setUp(() {
    gateway = _MockLocationGateway();
    source = GeolocatorPermissionSource(gateway);
  });

  const cases = {
    LocationPermission.always: PermissionStatus.granted,
    LocationPermission.whileInUse: PermissionStatus.granted,
    LocationPermission.denied: PermissionStatus.denied,
    LocationPermission.unableToDetermine: PermissionStatus.denied,
    LocationPermission.deniedForever: PermissionStatus.permanentlyDenied,
  };

  for (final MapEntry(key: platform, value: expected) in cases.entries) {
    test('check: $platform → $expected', () async {
      when(() => gateway.checkPermission()).thenAnswer((_) async => platform);
      expect(await source.check(), expected);
    });

    test('request: $platform → $expected', () async {
      when(() => gateway.requestPermission()).thenAnswer((_) async => platform);
      expect(await source.request(), expected);
    });
  }

  test('openSettings 는 앱 설정을 연다', () async {
    when(() => gateway.openAppSettings()).thenAnswer((_) async => true);
    await source.openSettings();
    verify(() => gateway.openAppSettings()).called(1);
  });
}
