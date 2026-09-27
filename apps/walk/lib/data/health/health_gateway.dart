import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/period_range.dart';

/// `health` 패키지를 얇게 감싼다. 플랫폼 호출이라 mock 하기 어려운 것을 이 뒤로
/// 숨겨 repository 를 단위 테스트한다 (commute 의 `LocationGateway` 와 같은 이유).
abstract interface class HealthGateway {
  /// Health Connect 상태. 알 수 없으면 null.
  Future<HealthConnectSdkStatus?> sdkStatus();

  /// 플레이스토어의 Health Connect 설치 · 업데이트 화면을 연다.
  Future<void> installHealthConnect();

  Future<bool> hasPermission(HealthDataType type);

  /// 읽기 권한 요청 화면을 띄운다.
  Future<bool> requestPermissions(List<HealthDataType> types);

  /// 30일보다 오래된 기록 읽기 권한. 이미 있으면 묻지 않는다.
  Future<bool> requestHistoryPermission();

  /// Health Connect 의 앱 권한 설정 화면을 연다(두 번 거부하면 다이얼로그가 안 뜨므로).
  Future<void> openHealthConnectSettings();

  /// 로컬 자정 [from] 부터 [to](포함) 까지 날짜(로컬 자정) 별 [types] 합계를 한 번에 묻는다.
  /// 기록이 없는 날 · type 은 키가 없다.
  Future<Map<DateTime, Map<HealthDataType, double>>> dailyTotals(
    DateTime from,
    DateTime to,
    List<HealthDataType> types,
  );
}

@LazySingleton(as: HealthGateway)
class HealthPluginGateway implements HealthGateway {
  static const _channel = MethodChannel('com.karma.walk/health_connect');

  final Health _health = Health();
  Future<void>? _configured;

  Future<void> _ready() => _configured ??= _health.configure();

  @override
  Future<HealthConnectSdkStatus?> sdkStatus() async {
    await _ready();
    return _health.getHealthConnectSdkStatus();
  }

  @override
  Future<void> installHealthConnect() async {
    await _ready();
    await _health.installHealthConnect();
  }

  @override
  Future<bool> hasPermission(HealthDataType type) async {
    await _ready();
    return await _health.hasPermissions([type]) ?? false;
  }

  @override
  Future<bool> requestPermissions(List<HealthDataType> types) async {
    await _ready();
    return _health.requestAuthorization(types);
  }

  @override
  Future<bool> requestHistoryPermission() async {
    await _ready();
    if (!await _health.isHealthDataHistoryAvailable()) return false;
    if (await _health.isHealthDataHistoryAuthorized()) return true;
    return _health.requestHealthDataHistoryAuthorization();
  }

  @override
  Future<void> openHealthConnectSettings() =>
      _channel.invokeMethod<void>('openSettings');

  @override
  Future<Map<DateTime, Map<HealthDataType, double>>> dailyTotals(
    DateTime from,
    DateTime to,
    List<HealthDataType> types,
  ) async {
    await _ready();
    // interval 은 초 단위(health 13.3.2 네이티브가 Duration.ofSeconds 로 쓴다) — 하루 버킷.
    final points = await _health.getHealthIntervalDataFromTypes(
      startDate: from,
      endDate: DateTime(to.year, to.month, to.day + 1),
      types: types,
      interval: 86400,
    );
    final totals = <DateTime, Map<HealthDataType, double>>{};
    for (final point in points) {
      final value = point.value;
      if (value is! NumericHealthValue) continue;
      // 데이터 출처가 없는 버킷은 기록이 없는 날이다 — 0 으로 두면 `–` 대신 0 이 보인다.
      if (point.sourceName.isEmpty) continue;
      final amount = value.numericValue.toDouble();
      totals
          .putIfAbsent(dateOnly(point.dateFrom.toLocal()), () => {})
          .update(point.type, (sum) => sum + amount, ifAbsent: () => amount);
    }
    return totals;
  }
}
