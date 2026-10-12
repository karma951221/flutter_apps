import 'package:walk/domain/lock/device_auth.dart';

/// `local_auth` 대역(스펙 §9.1). 결과 · 화면 잠금 유무를 테스트가 정한다.
class FakeDeviceAuth implements DeviceAuth {
  FakeDeviceAuth({
    this.result = DeviceAuthResult.success,
    this.screenLock = true,
  });

  DeviceAuthResult result;
  bool screenLock;
  int calls = 0;

  @override
  Future<bool> hasScreenLock() async => screenLock;

  @override
  Future<DeviceAuthResult> authenticate(String reason) async {
    calls++;
    return result;
  }
}
