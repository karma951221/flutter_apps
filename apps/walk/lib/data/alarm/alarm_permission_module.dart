import 'package:injectable/injectable.dart';
import 'package:permission/permission.dart';

import '../../domain/alarm/permission/alarm_permissions.dart';
import 'exact_alarm_permission_source.dart';
import 'full_screen_intent_permission_source.dart';
import 'notification_permission_source.dart';

@module
abstract class AlarmPermissionModule {
  /// 요청기가 세션 기억을 가지므로 싱글턴이다.
  @lazySingleton
  AlarmPermissions get alarmPermissions => AlarmPermissions(
    notification: PermissionRequester(NotificationPermissionSource()),
    exactAlarm: PermissionRequester(ExactAlarmPermissionSource()),
    fullScreenIntent: PermissionRequester(FullScreenIntentPermissionSource()),
  );
}
