import 'package:core/core.dart';
import 'package:health/health.dart';
import 'package:injectable/injectable.dart';
import 'package:permission/permission.dart';

import '../../domain/entity/daily_activity.dart';
import '../../domain/entity/health_access.dart';
import '../../domain/entity/period_range.dart';
import '../../domain/repository/activity_repository.dart';
import '../health/health_gateway.dart';
import '../health/health_permission_source.dart';

@LazySingleton(as: ActivityRepository)
class HealthConnectActivityRepository implements ActivityRepository {
  HealthConnectActivityRepository(this._gateway)
    : _permission = PermissionRequester(HealthPermissionSource(_gateway));

  final HealthGateway _gateway;

  /// 세션 기억("이번 세션에 거부했다")을 가진다. 저장소가 싱글턴이라 앱 수명 동안 하나다.
  final PermissionRequester _permission;

  static const _steps = HealthDataType.STEPS;
  static const _distance = HealthDataType.DISTANCE_DELTA;
  static const _kcal = HealthDataType.ACTIVE_ENERGY_BURNED;

  @override
  Future<HealthAccess> access() async {
    try {
      return switch (await _gateway.sdkStatus()) {
        HealthConnectSdkStatus.sdkAvailable => _toAccess(await _permission.ensure()),
        HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
          HealthAccess.updateRequired,
        HealthConnectSdkStatus.sdkUnavailable || null => HealthAccess.notInstalled,
      };
    } on Object {
      return HealthAccess.permissionDenied;
    }
  }

  @override
  Future<HealthAccess> requestAccess() async {
    try {
      await _permission.requestAgain();
    } on Object {
      // 취소 · 플랫폼 오류도 여기로 온다. 결과는 아래 확인이 정한다.
    }
    // access() 는 ensure() 라 방금 거부했으면 다시 묻지 않는다.
    return access();
  }

  @override
  bool get permissionDeclinedThisSession => _permission.declinedThisSession;

  @override
  Future<void> openPermissionSettings() => _permission.openSettings();

  @override
  Future<void> openInstall() => _gateway.installHealthConnect();

  @override
  Future<Result<List<DailyActivity>>> dailyActivities(
    DateTime from,
    DateTime to,
  ) async {
    try {
      // 거리 · 칼로리 권한만 거부됐으면 그 타입을 묻지 않는다 — 물으면 예외가 난다.
      final types = [
        _steps,
        if (await _gateway.hasPermission(_distance)) _distance,
        if (await _gateway.hasPermission(_kcal)) _kcal,
      ];
      final days = daysBetween(from, to);
      final totals = await Future.wait(
        days.map((day) => _gateway.dayTotals(day, types)),
      );
      return Ok([
        for (var i = 0; i < days.length; i++)
          DailyActivity(
            date: days[i],
            steps: (totals[i][_steps] ?? 0).round(),
            distanceMeters: totals[i][_distance],
            activeKcal: totals[i][_kcal],
          ),
      ]);
    } on Object catch (e) {
      return Err(Failure.unknown(message: '걸음 기록을 읽지 못했다: $e'));
    }
  }

  static HealthAccess _toAccess(PermissionStatus status) => switch (status) {
    PermissionStatus.granted => HealthAccess.granted,
    PermissionStatus.denied ||
    PermissionStatus.permanentlyDenied => HealthAccess.permissionDenied,
  };
}
