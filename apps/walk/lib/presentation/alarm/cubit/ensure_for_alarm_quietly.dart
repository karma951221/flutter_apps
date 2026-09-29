import '../../../domain/alarm/permission/alarm_permissions.dart';

/// 알람을 저장 · 켠 **뒤에** 권한을 확인한다. 확인이 예외를 던져도 저장은 이미 끝났으니
/// 삼킨다 — 저장 실패로 보이면 화면이 머물고, 다시 저장해 같은 알람이 둘이 된다.
/// 권한이 여전히 없으면 목록 경고 배너가 알려준다.
Future<void> ensureForAlarmQuietly(AlarmPermissions permissions) async {
  try {
    await permissions.ensureForAlarm();
  } on Object {
    // 위 설명대로 무시한다.
  }
}
