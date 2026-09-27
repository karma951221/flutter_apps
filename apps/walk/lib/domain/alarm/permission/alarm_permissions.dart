import 'package:permission/permission.dart';

/// 알람이 쓰는 권한 요청기 묶음. 요청기는 "이번 세션에 거부함"을 기억하므로 앱 수명 동안
/// 하나씩이다 — DI 싱글턴으로 받는다. 알람 저장 · 켜기 때 [notification] → [exactAlarm]
/// 순서로 `ensure()` 하고, 거부돼도 저장은 한다(스펙 §7).
class AlarmPermissions {
  const AlarmPermissions({
    required this.notification,
    required this.exactAlarm,
    required this.fullScreenIntent,
  });

  final PermissionRequester notification;
  final PermissionRequester exactAlarm;

  /// Android 14+ 에서 거부될 수 있다. 요청은 시스템 설정 화면을 여는 것뿐이라
  /// 결과는 복귀(resumed) 뒤 `check()` 로 다시 읽는다.
  final PermissionRequester fullScreenIntent;

  /// 알람 저장 · 켜기 뒤에 부른다. 이번 세션에 이미 거부했으면 다시 묻지 않는다.
  /// 거부돼도 알람은 이미 저장돼 있다 — 설정 탭 · 목록 경고가 남은 길이다.
  Future<void> ensureForAlarm() async {
    await notification.ensure();
    await exactAlarm.ensure();
  }

  /// 알람이 제때 울리는 데 꼭 필요한 두 권한이 모두 허용인가. (목록 경고 배너)
  Future<bool> canRing() async =>
      await notification.check() == PermissionStatus.granted &&
      await exactAlarm.check() == PermissionStatus.granted;
}
