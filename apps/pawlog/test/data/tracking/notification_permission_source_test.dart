import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/data/tracking/notification_permission_source.dart';
import 'package:permission/permission.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

void main() {
  test('permission_handler 상태를 세 가지로 접는다', () {
    const expected = {
      ph.PermissionStatus.granted: PermissionStatus.granted,
      ph.PermissionStatus.limited: PermissionStatus.granted,
      ph.PermissionStatus.provisional: PermissionStatus.granted,
      ph.PermissionStatus.denied: PermissionStatus.denied,
      ph.PermissionStatus.permanentlyDenied: PermissionStatus.permanentlyDenied,
      ph.PermissionStatus.restricted: PermissionStatus.permanentlyDenied,
    };

    for (final status in ph.PermissionStatus.values) {
      expect(
        NotificationPermissionSource.statusOf(status),
        expected[status],
        reason: '$status',
      );
    }
  });
}
