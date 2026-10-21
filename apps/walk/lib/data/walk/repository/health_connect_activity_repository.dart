import 'package:core/core.dart';
import 'package:health/health.dart';
import 'package:injectable/injectable.dart';
import 'package:permission/permission.dart';

import '../../../domain/walk/entity/daily_activity.dart';
import '../../../domain/walk/entity/health_access.dart';
import '../../../domain/walk/entity/period_range.dart';
import '../../../domain/walk/repository/activity_repository.dart';
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

  /// 진행 중인 확인 · 요청. 권한 화면이 앱을 멈췄다 되살리면 복귀 확인이 시작 확인과
  /// 겹친다 — 겹쳐 요청하면 화면이 두 번 뜨고, 플러그인은 대기 결과를 하나만 들고 있어
  /// 한쪽 future 가 영영 끝나지 않는다. 그래서 끝날 때까지 같은 future 를 나눠 준다.
  Future<HealthAccess>? _inFlight;

  @override
  Future<HealthAccess> access() =>
      _inFlight ??= _checkAccess().whenComplete(() => _inFlight = null);

  @override
  Future<HealthAccess> requestAccess() =>
      _inFlight ??= _requestThenCheck().whenComplete(() => _inFlight = null);

  Future<HealthAccess> _checkAccess() async {
    try {
      return switch (await _gateway.sdkStatus()) {
        HealthConnectSdkStatus.sdkAvailable => _toAccess(
          await _permission.ensure(),
        ),
        HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
          HealthAccess.updateRequired,
        HealthConnectSdkStatus.sdkUnavailable ||
        null => HealthAccess.notInstalled,
      };
    } on Object {
      return HealthAccess.permissionDenied;
    }
  }

  Future<HealthAccess> _requestThenCheck() async {
    try {
      await _permission.requestAgain();
    } on Object {
      // 취소 · 플랫폼 오류도 여기로 온다. 결과는 아래 확인이 정한다.
    }
    // ensure() 라 방금 거부했으면 다시 묻지 않는다. access() 를 부르면 자기 자신을 기다린다.
    return _checkAccess();
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
      final totals = await _gateway.dailyTotals(from, to, const [_steps]);
      return Ok([
        for (final day in daysBetween(from, to))
          DailyActivity(date: day, steps: (totals[day]?[_steps] ?? 0).round()),
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
