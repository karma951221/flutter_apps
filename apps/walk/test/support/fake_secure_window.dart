import 'package:walk/domain/chat/secure_window.dart';

/// 받은 값을 모으는 [SecureWindow].
class FakeSecureWindow implements SecureWindow {
  /// [setSecure] 로 받은 값들(부른 순서대로).
  final calls = <bool>[];

  @override
  Future<void> setSecure(bool on) async => calls.add(on);
}
