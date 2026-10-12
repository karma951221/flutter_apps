import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/data/lock/local_auth_device_auth.dart';
import 'package:walk/domain/lock/device_auth.dart';

class _MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late _MockLocalAuthentication auth;
  late LocalAuthDeviceAuth deviceAuth;

  setUp(() {
    auth = _MockLocalAuthentication();
    deviceAuth = LocalAuthDeviceAuth(auth);
  });

  void authenticateReturns(Future<bool> Function() answer) {
    when(
      () => auth.authenticate(
        localizedReason: any(named: 'localizedReason'),
        biometricOnly: any(named: 'biometricOnly'),
      ),
    ).thenAnswer((_) => answer());
  }

  group('hasScreenLock', () {
    test('화면 잠금이 없으면 false', () async {
      when(() => auth.isDeviceSupported()).thenAnswer((_) async => false);

      expect(await deviceAuth.hasScreenLock(), isFalse);
    });

    test('화면 잠금이 있으면 true', () async {
      when(() => auth.isDeviceSupported()).thenAnswer((_) async => true);

      expect(await deviceAuth.hasScreenLock(), isTrue);
    });

    test('플랫폼 오류면 false', () async {
      when(
        () => auth.isDeviceSupported(),
      ).thenThrow(PlatformException(code: 'channel-error'));

      expect(await deviceAuth.hasScreenLock(), isFalse);
    });
  });

  group('authenticate', () {
    test('기기 PIN 도 허용하고 이유를 넘긴다', () async {
      authenticateReturns(() async => true);

      await deviceAuth.authenticate('다시 설정하려면 인증해 주세요');

      verify(
        () => auth.authenticate(
          localizedReason: '다시 설정하려면 인증해 주세요',
          biometricOnly: false,
        ),
      ).called(1);
    });

    test('true → 성공', () async {
      authenticateReturns(() async => true);

      expect(await deviceAuth.authenticate('r'), DeviceAuthResult.success);
    });

    test('false → 실패', () async {
      authenticateReturns(() async => false);

      expect(await deviceAuth.authenticate('r'), DeviceAuthResult.failed);
    });

    Future<DeviceAuthResult> throwing(LocalAuthExceptionCode code) {
      authenticateReturns(() => throw LocalAuthException(code: code));
      return deviceAuth.authenticate('r');
    }

    test('사용자 · 시스템이 닫거나 시간이 지나면 취소(실패 아님)', () async {
      for (final code in [
        LocalAuthExceptionCode.userCanceled,
        LocalAuthExceptionCode.systemCanceled,
        LocalAuthExceptionCode.timeout,
        LocalAuthExceptionCode.authInProgress,
        LocalAuthExceptionCode.userRequestedFallback,
      ]) {
        expect(
          await throwing(code),
          DeviceAuthResult.canceled,
          reason: '$code',
        );
      }
    });

    test('화면 잠금이 없거나 쓸 수 없으면 unavailable', () async {
      for (final code in [
        LocalAuthExceptionCode.noCredentialsSet,
        LocalAuthExceptionCode.noBiometricsEnrolled,
        LocalAuthExceptionCode.noBiometricHardware,
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable,
        LocalAuthExceptionCode.uiUnavailable,
        LocalAuthExceptionCode.deviceError,
        LocalAuthExceptionCode.unknownError,
      ]) {
        expect(
          await throwing(code),
          DeviceAuthResult.unavailable,
          reason: '$code',
        );
      }
    });

    test('폰이 인증을 잠갔으면 lockedOut', () async {
      expect(
        await throwing(LocalAuthExceptionCode.temporaryLockout),
        DeviceAuthResult.lockedOut,
      );
      expect(
        await throwing(LocalAuthExceptionCode.biometricLockout),
        DeviceAuthResult.lockedOut,
      );
    });

    test('채널 오류(PlatformException)는 unavailable', () async {
      authenticateReturns(() => throw PlatformException(code: 'NotAvailable'));

      expect(await deviceAuth.authenticate('r'), DeviceAuthResult.unavailable);
    });
  });
}
