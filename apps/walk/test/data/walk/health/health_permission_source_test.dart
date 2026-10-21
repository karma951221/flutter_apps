import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/data/walk/health/health_gateway.dart';
import 'package:walk/data/walk/health/health_permission_source.dart';

class _MockGateway extends Mock implements HealthGateway {}

void main() {
  late _MockGateway gateway;
  late HealthPermissionSource source;

  setUpAll(() => registerFallbackValue(HealthDataType.STEPS));
  setUp(() {
    gateway = _MockGateway();
    source = HealthPermissionSource(gateway);
  });

  test('걸음 권한이 있으면 granted, 없으면 denied — permanentlyDenied 는 주지 않는다', () async {
    when(() => gateway.hasPermission(HealthDataType.STEPS)).thenAnswer((_) async => true);
    expect(await source.check(), PermissionStatus.granted);

    when(() => gateway.hasPermission(HealthDataType.STEPS)).thenAnswer((_) async => false);
    expect(await source.check(), PermissionStatus.denied);
  });

  test('request 는 세 타입과 기록 이력 권한을 요청하고 걸음 권한으로 판정한다', () async {
    when(() => gateway.requestPermissions(any())).thenAnswer((_) async => true);
    when(() => gateway.requestHistoryPermission()).thenAnswer((_) async => false);
    when(() => gateway.hasPermission(HealthDataType.STEPS)).thenAnswer((_) async => true);

    expect(await source.request(), PermissionStatus.granted);
    verify(() => gateway.requestPermissions(const [
          HealthDataType.STEPS,
          HealthDataType.DISTANCE_DELTA,
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ])).called(1);
    verify(() => gateway.requestHistoryPermission()).called(1);
  });

  test('걸음 권한을 거부하면 기록 이력은 묻지 않는다', () async {
    when(() => gateway.requestPermissions(any())).thenAnswer((_) async => false);
    when(() => gateway.hasPermission(HealthDataType.STEPS)).thenAnswer((_) async => false);

    expect(await source.request(), PermissionStatus.denied);
    verifyNever(() => gateway.requestHistoryPermission());
  });

  test('openSettings 는 Health Connect 설정을 연다', () async {
    when(() => gateway.openHealthConnectSettings()).thenAnswer((_) async {});
    await source.openSettings();
    verify(() => gateway.openHealthConnectSettings()).called(1);
  });
}
