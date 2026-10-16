import 'package:flutter_test/flutter_test.dart';
import 'package:location/location.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';

class _MockLocationGateway extends Mock implements LocationGateway {}

void main() {
  late _MockLocationGateway gateway;
  late LocationAccess access;

  setUp(() {
    gateway = _MockLocationGateway();
    access = LocationAccess(gateway);
    when(
      () => gateway.isLocationServiceEnabled(),
    ).thenAnswer((_) async => true);
  });

  test('위치 서비스가 꺼져 있으면 권한을 보지 않고 serviceDisabled', () async {
    when(
      () => gateway.isLocationServiceEnabled(),
    ).thenAnswer((_) async => false);

    expect(await access.ensure(), LocationAccessStatus.serviceDisabled);
    verifyNever(() => gateway.checkPermission());
  });

  test('이미 허용돼 있으면 묻지 않고 granted', () async {
    when(
      () => gateway.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.whileInUse);

    expect(await access.ensure(), LocationAccessStatus.granted);
    verifyNever(() => gateway.requestPermission());
  });

  test('거부 상태면 한 번 물어 허용되면 granted', () async {
    when(
      () => gateway.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.denied);
    when(
      () => gateway.requestPermission(),
    ).thenAnswer((_) async => LocationPermission.whileInUse);

    expect(await access.ensure(), LocationAccessStatus.granted);
    verify(() => gateway.requestPermission()).called(1);
  });

  test('요청을 거부하면 permissionDenied 이고 같은 세션에서 다시 묻지 않는다', () async {
    when(
      () => gateway.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.denied);
    when(
      () => gateway.requestPermission(),
    ).thenAnswer((_) async => LocationPermission.denied);

    expect(await access.ensure(), LocationAccessStatus.permissionDenied);
    expect(await access.ensure(), LocationAccessStatus.permissionDenied);
    verify(() => gateway.requestPermission()).called(1);
    expect(access.permission.declinedThisSession, isTrue);
  });

  test('영구 거부면 요청 없이 permissionDenied', () async {
    when(
      () => gateway.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.deniedForever);

    expect(await access.ensure(), LocationAccessStatus.permissionDenied);
    verifyNever(() => gateway.requestPermission());
    expect(await access.permission.check(), PermissionStatus.permanentlyDenied);
  });

  group('check', () {
    test('서비스가 꺼져 있으면 serviceDisabled', () async {
      when(
        () => gateway.isLocationServiceEnabled(),
      ).thenAnswer((_) async => false);

      expect(await access.check(), LocationAccessStatus.serviceDisabled);
      verifyNever(() => gateway.checkPermission());
    });

    test('허용돼 있으면 granted', () async {
      when(
        () => gateway.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.always);

      expect(await access.check(), LocationAccessStatus.granted);
    });

    test('거부 상태여도 묻지 않고 permissionDenied, 세션 기억도 쓰지 않는다', () async {
      when(
        () => gateway.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);
      when(
        () => gateway.requestPermission(),
      ).thenAnswer((_) async => LocationPermission.whileInUse);

      expect(await access.check(), LocationAccessStatus.permissionDenied);
      verifyNever(() => gateway.requestPermission());
      expect(access.permission.declinedThisSession, isFalse);

      // 한 번 묻기는 그대로 남아 있다.
      expect(await access.ensure(), LocationAccessStatus.granted);
      verify(() => gateway.requestPermission()).called(1);
    });
  });

  test('위치 설정 열기는 게이트웨이에 맡긴다', () async {
    when(() => gateway.openLocationSettings()).thenAnswer((_) async => true);

    await access.openLocationSettings();

    verify(() => gateway.openLocationSettings()).called(1);
  });
}
