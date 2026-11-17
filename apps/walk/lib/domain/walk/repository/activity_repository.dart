import 'package:core/core.dart';

import '../entity/daily_activity.dart';
import '../entity/health_access.dart';

abstract interface class ActivityRepository {
  /// 예외를 던지지 않는다. 확인 자체가 실패하면 [HealthAccess.permissionDenied].
  /// Health Connect 가 있고 권한이 없으면 **이번 세션에 한 번만** 요청 화면을 띄운다.
  Future<HealthAccess> access();

  /// 사용자가 "권한 허용"을 눌렀을 때. 세션 기억과 무관하게 요청한 뒤 다시 확인한다.
  Future<HealthAccess> requestAccess();

  /// 이번 세션에 권한 요청을 거부했는지 — 화면이 "설정 열기"를 함께 보인다.
  bool get permissionDeclinedThisSession;

  /// Health Connect 의 앱 권한 설정 화면.
  Future<void> openPermissionSettings();

  Future<void> openInstall();

  /// [from] 부터 [to] 까지(자정, 양 끝 포함) 모든 날. 기록 없는 날은 [DailyActivity.empty].
  Future<Result<List<DailyActivity>>> dailyActivities(DateTime from, DateTime to);
}
