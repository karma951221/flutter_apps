import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/data/health/health_gateway.dart';
import 'package:walk/data/repository/health_connect_activity_repository.dart';
import 'package:walk/domain/entity/daily_activity.dart';
import 'package:walk/domain/entity/health_access.dart';

class _MockGateway extends Mock implements HealthGateway {}

const _steps = HealthDataType.STEPS;
const _distance = HealthDataType.DISTANCE_DELTA;
const _kcal = HealthDataType.ACTIVE_ENERGY_BURNED;

void main() {
  late _MockGateway gateway;
  late HealthConnectActivityRepository repository;

  setUpAll(() {
    registerFallbackValue(_steps);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(<HealthDataType>[]);
  });

  setUp(() {
    gateway = _MockGateway();
    repository = HealthConnectActivityRepository(gateway);
    when(() => gateway.hasPermission(any())).thenAnswer((_) async => true);
    when(() => gateway.sdkStatus())
        .thenAnswer((_) async => HealthConnectSdkStatus.sdkAvailable);
    when(() => gateway.requestPermissions(any())).thenAnswer((_) async => false);
    when(() => gateway.requestHistoryPermission()).thenAnswer((_) async => true);
  });

  group('access', () {
    test('SDK 없음 → notInstalled, 권한은 묻지 않는다', () async {
      when(() => gateway.sdkStatus())
          .thenAnswer((_) async => HealthConnectSdkStatus.sdkUnavailable);
      expect(await repository.access(), HealthAccess.notInstalled);
      verifyNever(() => gateway.requestPermissions(any()));
    });

    test('상태를 모름(null) → notInstalled', () async {
      when(() => gateway.sdkStatus()).thenAnswer((_) async => null);
      expect(await repository.access(), HealthAccess.notInstalled);
    });

    test('업데이트 필요 → updateRequired', () async {
      when(() => gateway.sdkStatus()).thenAnswer(
          (_) async => HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired);
      expect(await repository.access(), HealthAccess.updateRequired);
    });

    test('걸음 권한이 있으면 granted — 거리 · 칼로리는 따지지 않고 묻지도 않는다', () async {
      when(() => gateway.hasPermission(_distance)).thenAnswer((_) async => false);
      expect(await repository.access(), HealthAccess.granted);
      verifyNever(() => gateway.requestPermissions(any()));
    });

    test('권한이 없으면 이번 세션에 한 번만 묻는다', () async {
      when(() => gateway.hasPermission(_steps)).thenAnswer((_) async => false);

      expect(await repository.access(), HealthAccess.permissionDenied);
      expect(await repository.access(), HealthAccess.permissionDenied);

      verify(() => gateway.requestPermissions(any())).called(1);
      expect(repository.permissionDeclinedThisSession, isTrue);
    });

    test('확인 중 예외 → permissionDenied', () async {
      when(() => gateway.sdkStatus()).thenThrow(Exception('boom'));
      expect(await repository.access(), HealthAccess.permissionDenied);
    });
  });

  group('requestAccess', () {
    test('이미 거부했어도 다시 묻고, 허용하면 granted', () async {
      var granted = false;
      when(() => gateway.hasPermission(_steps)).thenAnswer((_) async => granted);
      await repository.access(); // 한 번 거부

      when(() => gateway.requestPermissions(any())).thenAnswer((_) async {
        granted = true;
        return true;
      });

      expect(await repository.requestAccess(), HealthAccess.granted);
      verify(() => gateway.requestPermissions(any())).called(2);
      expect(repository.permissionDeclinedThisSession, isFalse);
    });

    test('요청 중 예외여도 확인한 상태를 돌려준다', () async {
      when(() => gateway.requestPermissions(any())).thenThrow(Exception('boom'));
      when(() => gateway.hasPermission(_steps)).thenAnswer((_) async => false);
      expect(await repository.requestAccess(), HealthAccess.permissionDenied);
    });
  });

  test('openPermissionSettings 는 Health Connect 설정을 연다', () async {
    when(() => gateway.openHealthConnectSettings()).thenAnswer((_) async {});
    await repository.openPermissionSettings();
    verify(() => gateway.openHealthConnectSettings()).called(1);
  });

  group('dailyActivities', () {
    test('모든 날을 채우고 없는 값은 0보 · null', () async {
      when(() => gateway.dayTotals(DateTime(2026, 9, 21), any()))
          .thenAnswer((_) async => {_steps: 6240, _distance: 4310.5, _kcal: 182.4});
      when(() => gateway.dayTotals(DateTime(2026, 9, 22), any()))
          .thenAnswer((_) async => {_steps: 1200});
      when(() => gateway.dayTotals(DateTime(2026, 9, 23), any()))
          .thenAnswer((_) async => {});

      final result =
          await repository.dailyActivities(DateTime(2026, 9, 21), DateTime(2026, 9, 23));

      expect((result as Ok<List<DailyActivity>>).value, [
        DailyActivity(
          date: DateTime(2026, 9, 21),
          steps: 6240,
          distanceMeters: 4310.5,
          activeKcal: 182.4,
        ),
        DailyActivity(date: DateTime(2026, 9, 22), steps: 1200),
        DailyActivity.empty(DateTime(2026, 9, 23)),
      ]);
    });

    test('권한이 없는 타입은 묻지 않는다', () async {
      when(() => gateway.hasPermission(_kcal)).thenAnswer((_) async => false);
      when(() => gateway.dayTotals(any(), any())).thenAnswer((_) async => {});

      await repository.dailyActivities(DateTime(2026, 9, 21), DateTime(2026, 9, 21));

      verify(() => gateway.dayTotals(DateTime(2026, 9, 21), [_steps, _distance]))
          .called(1);
    });

    test('예외 → Err(unknown)', () async {
      when(() => gateway.dayTotals(any(), any())).thenThrow(Exception('boom'));

      final result =
          await repository.dailyActivities(DateTime(2026, 9, 21), DateTime(2026, 9, 21));

      expect(result, isA<Err<List<DailyActivity>>>());
      expect((result as Err).failure, isA<UnknownFailure>());
    });
  });
}
