import 'package:permission_handler/permission_handler.dart' as ph;

import 'permission_handler_source.dart';

/// Android 12+ 정확한 알람. 런타임 다이얼로그가 없고 요청하면 "알람 및 리마인더" 설정
/// 화면이 열린다. 13+ 는 `USE_EXACT_ALARM` 선언으로 기본 허용이라 대개 granted 다.
class ExactAlarmPermissionSource extends PermissionHandlerSource {
  ExactAlarmPermissionSource() : super(ph.Permission.scheduleExactAlarm);

  /// 앱 정보 화면보다 해당 설정 화면이 바로 열리는 요청 쪽이 낫다.
  @override
  Future<void> openSettings() async {
    await permission.request();
  }
}
