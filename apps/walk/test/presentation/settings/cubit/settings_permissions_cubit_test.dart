import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/walk/entity/health_access.dart';
import 'package:walk/domain/walk/usecase/walk_use_case.dart';
import 'package:walk/presentation/settings/cubit/settings_permissions_cubit.dart';
import 'package:walk/presentation/settings/cubit/settings_permissions_state.dart';

class _MockRequester extends Mock implements PermissionRequester {}

class _MockWalk extends Mock implements WalkUseCase {}

void main() {
  late _MockRequester notification;
  late _MockRequester exactAlarm;
  late _MockRequester fullScreen;
  late _MockWalk walk;

  SettingsPermissionsCubit build() => SettingsPermissionsCubit(
    AlarmPermissions(
      notification: notification,
      exactAlarm: exactAlarm,
      fullScreenIntent: fullScreen,
    ),
    walk,
  );

  setUp(() {
    notification = _MockRequester();
    exactAlarm = _MockRequester();
    fullScreen = _MockRequester();
    walk = _MockWalk();
    when(
      () => notification.check(),
    ).thenAnswer((_) async => PermissionStatus.denied);
    when(
      () => exactAlarm.check(),
    ).thenAnswer((_) async => PermissionStatus.granted);
    when(
      () => fullScreen.check(),
    ).thenAnswer((_) async => PermissionStatus.permanentlyDenied);
    when(() => walk.access()).thenAnswer((_) async => HealthAccess.granted);
    when(() => walk.permissionDeclinedThisSession).thenReturn(false);
    for (final r in [notification, exactAlarm, fullScreen]) {
      when(r.openSettings).thenAnswer((_) async {});
      when(r.requestAgain).thenAnswer((_) async => PermissionStatus.granted);
    }
    when(walk.openPermissionSettings).thenAnswer((_) async {});
    when(walk.openInstall).thenAnswer((_) async {});
    when(walk.requestAccess).thenAnswer((_) async => HealthAccess.granted);
  });

  const checked = SettingsPermissionsState(
    notification: PermissionStatus.denied,
    exactAlarm: PermissionStatus.granted,
    fullScreenIntent: PermissionStatus.permanentlyDenied,
    health: HealthAccess.granted,
  );

  blocTest<SettingsPermissionsCubit, SettingsPermissionsState>(
    'check 는 네 권한을 모두 읽는다',
    build: build,
    act: (cubit) => cubit.check(),
    expect: () => [checked],
  );

  blocTest<SettingsPermissionsCubit, SettingsPermissionsState>(
    '알림이 denied 면 다시 묻고, 다시 읽는다',
    build: build,
    act: (cubit) => cubit.openNotification(),
    expect: () => [checked],
    verify: (_) {
      verify(notification.requestAgain).called(1);
      verifyNever(notification.openSettings);
    },
  );

  blocTest<SettingsPermissionsCubit, SettingsPermissionsState>(
    '알림이 영구 거부면 설정을 연다',
    build: () {
      when(
        () => notification.check(),
      ).thenAnswer((_) async => PermissionStatus.permanentlyDenied);
      return build();
    },
    act: (cubit) => cubit.openNotification(),
    verify: (_) {
      verify(notification.openSettings).called(1);
      verifyNever(notification.requestAgain);
    },
  );

  blocTest<SettingsPermissionsCubit, SettingsPermissionsState>(
    '정확한 알람 · 전체 화면 알림은 설정을 연다',
    build: build,
    act: (cubit) async {
      await cubit.openExactAlarm();
      await cubit.openFullScreenIntent();
    },
    verify: (_) {
      verify(exactAlarm.openSettings).called(1);
      verify(fullScreen.openSettings).called(1);
    },
  );

  blocTest<SettingsPermissionsCubit, SettingsPermissionsState>(
    'Health Connect: 거부면 요청, 이번 세션에 거부했으면 설정',
    build: build,
    seed: () =>
        const SettingsPermissionsState(health: HealthAccess.permissionDenied),
    act: (cubit) async {
      await cubit.openHealth();
      when(() => walk.permissionDeclinedThisSession).thenReturn(true);
      cubit.emit(
        const SettingsPermissionsState(health: HealthAccess.permissionDenied),
      );
      await cubit.openHealth();
    },
    verify: (_) {
      verify(walk.requestAccess).called(1);
      verify(walk.openPermissionSettings).called(1);
    },
  );

  blocTest<SettingsPermissionsCubit, SettingsPermissionsState>(
    'Health Connect: 설치 안 됨이면 스토어',
    build: build,
    seed: () =>
        const SettingsPermissionsState(health: HealthAccess.notInstalled),
    act: (cubit) => cubit.openHealth(),
    verify: (_) => verify(walk.openInstall).called(1),
  );
}
