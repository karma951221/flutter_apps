import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

import '../../domain/lock/device_auth.dart';

/// `local_auth` 3.x 로 폰 화면 잠금 인증(스펙 §11). 기기 PIN 도 허용한다.
///
/// 3.x 는 실패 대부분을 `false` 가 아니라 [LocalAuthException] 으로 던진다 — 특히 사용자가
/// 창을 닫으면 `userCanceled`. 취소류는 [DeviceAuthResult.canceled] 로 돌려 실패로 세지 않는다.
@LazySingleton(as: DeviceAuth)
class LocalAuthDeviceAuth implements DeviceAuth {
  LocalAuthDeviceAuth(this._auth);

  final LocalAuthentication _auth;

  /// 기기에 PIN · 패턴 · 비밀번호 같은 화면 잠금이 있으면 true(Android `isDeviceSupported`).
  @override
  Future<bool> hasScreenLock() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<DeviceAuthResult> authenticate(String reason) async {
    try {
      final passed = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
      );
      // Android 에서 false 는 사실상 나오지 않지만 나오면 실패로 본다.
      return passed ? DeviceAuthResult.success : DeviceAuthResult.failed;
    } on LocalAuthException catch (e) {
      return _fromCode(e.code);
    } on PlatformException {
      return DeviceAuthResult.unavailable;
    }
  }

  static DeviceAuthResult _fromCode(LocalAuthExceptionCode code) =>
      switch (code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.authInProgress ||
        LocalAuthExceptionCode.userRequestedFallback =>
          DeviceAuthResult.canceled,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout => DeviceAuthResult.lockedOut,
        // 인증 결과가 아닌 기기 · 설정 문제 — 24시간 차단으로 이어지지 않게 실패로 세지 않는다.
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable ||
        LocalAuthExceptionCode.uiUnavailable ||
        LocalAuthExceptionCode.deviceError ||
        LocalAuthExceptionCode.unknownError => DeviceAuthResult.unavailable,
      };
}
