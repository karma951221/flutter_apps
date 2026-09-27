import 'package:flutter_test/flutter_test.dart';
import 'package:permission/permission.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:walk/data/alarm/permission_handler_source.dart';

void main() {
  test('permission_handler 상태를 공용 상태로 바꾼다', () {
    const expected = {
      ph.PermissionStatus.granted: PermissionStatus.granted,
      ph.PermissionStatus.limited: PermissionStatus.granted,
      ph.PermissionStatus.provisional: PermissionStatus.granted,
      ph.PermissionStatus.denied: PermissionStatus.denied,
      ph.PermissionStatus.permanentlyDenied: PermissionStatus.permanentlyDenied,
      ph.PermissionStatus.restricted: PermissionStatus.permanentlyDenied,
    };
    for (final MapEntry(:key, :value) in expected.entries) {
      expect(PermissionHandlerSource.statusOf(key), value, reason: '$key');
    }
  });
}
