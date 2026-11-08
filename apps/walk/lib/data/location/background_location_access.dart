import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// 위치 "항상 허용" 확인 결과.
enum AlwaysAccess {
  /// 항상 허용됨.
  granted,

  /// 대화상자로 받을 수 없다 — 시스템 설정에서 직접 "항상 허용"으로 바꿔야 한다.
  needsSettings,

  /// 거부됐다.
  denied,
}

/// 백그라운드 위치 기록에 필요한 권한 · 설정 화면.
///
/// 활동 인식(`ACTIVITY_RECOGNITION`) · 알림 거부는 [AlwaysAccess] 에 영향이 없다 —
/// 기록은 켜지고 정지 감지만 꺼진다.
abstract interface class BackgroundLocationAccess {
  Future<AlwaysAccess> check();

  /// 앱 사용 중 → 항상 → 신체 활동 → 알림 순으로 묻는다.
  Future<AlwaysAccess> request();

  /// 신체 활동 권한이 있는가(정지 감지).
  Future<bool> hasActivityRecognition();

  /// 알림 권한이 있는가(기록 중 알림).
  Future<bool> hasNotification();

  Future<void> openAppSettings();
  Future<void> openBatterySettings();
}

@LazySingleton(as: BackgroundLocationAccess)
class PermissionHandlerBackgroundLocationAccess
    implements BackgroundLocationAccess {
  const PermissionHandlerBackgroundLocationAccess();

  @override
  Future<AlwaysAccess> check() async {
    final always = await ph.Permission.locationAlways.status;
    return always.isGranted ? AlwaysAccess.granted : AlwaysAccess.denied;
  }

  @override
  Future<AlwaysAccess> request() async {
    final whenInUse = await ph.Permission.locationWhenInUse.request();
    if (!whenInUse.isGranted) return AlwaysAccess.denied;
    final always = await ph.Permission.locationAlways.request();
    if (!always.isGranted) {
      // 안드로이드 11+ 는 "항상 허용"을 대화상자로 주지 않는다 — 설정에서 바꿔야 한다.
      return AlwaysAccess.needsSettings;
    }
    // 아래 둘은 거부해도 결과가 그대로다. 정지 감지 · 알림만 빠진다.
    await ph.Permission.activityRecognition.request();
    await ph.Permission.notification.request();
    return AlwaysAccess.granted;
  }

  @override
  Future<bool> hasActivityRecognition() =>
      ph.Permission.activityRecognition.isGranted;

  @override
  Future<bool> hasNotification() => ph.Permission.notification.isGranted;

  @override
  Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }

  @override
  Future<void> openBatterySettings() async {
    await ph.Permission.ignoreBatteryOptimizations.request();
  }
}
