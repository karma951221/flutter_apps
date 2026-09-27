import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/data/walk/health/health_gateway.dart';
import 'package:walk/data/walk/repository/health_connect_activity_repository.dart';
import 'package:walk/domain/walk/entity/daily_activity.dart';
import 'package:walk/domain/walk/entity/health_access.dart';

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

    test('확인이 진행 중이면 겹쳐 부르지 않고 같은 결과를 기다린다', () async {
      final pending = Completer<bool>();
      var granted = false;
      when(() => gateway.hasPermission(_steps)).thenAnswer((_) async => granted);
      when(() => gateway.requestPermissions(any())).thenAnswer((_) async {
        final result = await pending.future;
        granted = true;
        return result;
      });

      final first = repository.access();
      await pumpEventQueue(); // 첫 요청 화면이 떠 있는 동안
      final second = repository.access(); // 복귀가 다시 확인한다
      await pumpEventQueue();
      pending.complete(true);

      expect(await first, HealthAccess.granted);
      expect(await second, HealthAccess.granted);
      verify(() => gateway.requestPermissions(any())).called(1);
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
    test('한 번에 묻고 모든 날을 채운다 — 없는 값은 0보 · null', () async {
      when(() => gateway.dailyTotals(any(), any(), any())).thenAnswer(
        (_) async => {
          DateTime(2026, 9, 21): {_steps: 6240, _distance: 4310.5, _kcal: 182.4},
          DateTime(2026, 9, 22): {_steps: 1200},
        },
      );

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
      verify(
        () => gateway.dailyTotals(
          DateTime(2026, 9, 21),
          DateTime(2026, 9, 23),
          [_steps, _distance, _kcal],
        ),
      ).called(1);
    });

    test('권한이 없는 타입은 묻지 않는다', () async {
      when(() => gateway.hasPermission(_kcal)).thenAnswer((_) async => false);
      when(() => gateway.dailyTotals(any(), any(), any()))
          .thenAnswer((_) async => {});

      await repository.dailyActivities(DateTime(2026, 9, 21), DateTime(2026, 9, 21));

      verify(
        () => gateway.dailyTotals(
          DateTime(2026, 9, 21),
          DateTime(2026, 9, 21),
          [_steps, _distance],
        ),
      ).called(1);
    });

    test('예외 → Err(unknown)', () async {
      when(() => gateway.dailyTotals(any(), any(), any()))
          .thenThrow(Exception('boom'));

      final result =
          await repository.dailyActivities(DateTime(2026, 9, 21), DateTime(2026, 9, 21));

      expect(result, isA<Err<List<DailyActivity>>>());
      expect((result as Err).failure, isA<UnknownFailure>());
    });
  });
}
