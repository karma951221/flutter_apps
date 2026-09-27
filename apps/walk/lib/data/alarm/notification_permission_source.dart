import 'package:permission_handler/permission_handler.dart' as ph;

import 'permission_handler_source.dart';

/// Android 13+ `POST_NOTIFICATIONS`. 12 이하는 늘 허용이다.
class NotificationPermissionSource extends PermissionHandlerSource {
  NotificationPermissionSource() : super(ph.Permission.notification);
}
