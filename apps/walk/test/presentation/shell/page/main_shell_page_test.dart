import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/app_info/app_info_source.dart';
import 'package:walk/domain/clock.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/domain/settings/repository/settings_repository.dart';
import 'package:walk/domain/walk/entity/health_access.dart';
import 'package:walk/domain/walk/usecase/walk_use_case.dart';
import 'package:walk/presentation/alarm/page/alarm_list_page.dart';
import 'package:walk/presentation/settings/cubit/theme_cubit.dart';
import 'package:walk/presentation/settings/page/settings_page.dart';
import 'package:walk/presentation/shell/page/main_shell_page.dart';
import 'package:walk/presentation/walk/page/walk_home_page.dart';

class _MockAlarmUseCase extends Mock implements AlarmUseCase {}

class _MockWalk extends Mock implements WalkUseCase {}

class _MockRequester extends Mock implements PermissionRequester {}

class _MockAppInfo extends Mock implements AppInfoSource {}

class _MockSettings extends Mock implements SettingsRepository {}

void main() {
  late _MockAlarmUseCase alarms;
  late _MockWalk walk;
  late _MockRequester notification;

  setUp(() {
    alarms = _MockAlarmUseCase();
    walk = _MockWalk();
    notification = _MockRequester();
    final exactAlarm = _MockRequester();
    final fullScreen = _MockRequester();
    for (final r in [notification, exactAlarm, fullScreen]) {
      when(r.check).thenAnswer((_) async => PermissionStatus.granted);
    }
    when(alarms.list).thenAnswer((_) async => []);
    when(alarms.nextRings).thenAnswer((_) async => {});
    when(alarms.sync).thenAnswer((_) async {});
    when(walk.access).thenAnswer((_) async => HealthAccess.permissionDenied);
    when(() => walk.permissionDeclinedThisSession).thenReturn(false);
    final appInfo = _MockAppInfo();
    when(appInfo.version).thenAnswer((_) async => '1.0.0 (1)');
    getIt
      ..registerSingleton<AlarmUseCase>(alarms)
      ..registerSingleton<WalkUseCase>(walk)
      ..registerSingleton<AppInfoSource>(appInfo)
      ..registerSingleton<Clock>(Clock())
      ..registerSingleton<AlarmPermissions>(
        AlarmPermissions(
          notification: notification,
          exactAlarm: exactAlarm,
          fullScreenIntent: fullScreen,
        ),
      );
  });
  tearDown(getIt.reset);

  Future<void> pump(WidgetTester tester) async {
    final settings = _MockSettings();
    when(settings.load).thenReturn(const AppSettings());
    final theme = ThemeCubit(settings);
    addTearDown(theme.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: theme,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorObservers: [appRouteObserver],
          home: const MainShellPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool onstage(Type page) =>
      find.byType(page).hitTestable().evaluate().isNotEmpty;

  testWidgets('첫 탭은 걷기, 시작할 때 예약을 동기화한다', (tester) async {
    await pump(tester);

    expect(onstage(WalkHomePage), isTrue);
    expect(onstage(AlarmListPage), isFalse);
    verify(alarms.sync).called(1);
  });

  testWidgets('탭을 누르면 해당 화면으로 바뀐다', (tester) async {
    await pump(tester);

    await tester.tap(find.byIcon(Icons.alarm));
    await tester.pumpAndSettle();
    expect(onstage(AlarmListPage), isTrue);
    expect(find.text('알람이 없어요'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(onstage(SettingsPage), isTrue);
    expect(onstage(AlarmListPage), isFalse);
  });

  testWidgets('복귀하면 다시 동기화한다', (tester) async {
    await pump(tester);
    clearInteractions(alarms);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    verify(alarms.sync).called(1);
  });

  testWidgets('위에 얹힌 울림 화면이 걷히면 예약을 동기화한 뒤 목록을 다시 읽는다', (tester) async {
    await pump(tester);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const Text('ringing')),
      ),
    );
    await tester.pumpAndSettle();
    clearInteractions(alarms);

    navigator.pop();
    await tester.pumpAndSettle();

    verifyInOrder([alarms.sync, alarms.list]);
  });

  void resume(WidgetTester tester) {
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  testWidgets('복귀하면 설정 권한 행을 다시 읽는다', (tester) async {
    when(notification.check).thenAnswer((_) async => PermissionStatus.denied);
    await pump(tester);
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    // 알림 · Health Connect 가 허용 필요.
    expect(find.text('허용 필요 ›'), findsNWidgets(2));

    // 시스템 설정에서 알림을 허용하고 돌아왔다.
    when(notification.check).thenAnswer((_) async => PermissionStatus.granted);
    resume(tester);
    await tester.pumpAndSettle();

    expect(find.text('허용 필요 ›'), findsOneWidget);
    expect(find.text('허용됨'), findsNWidgets(3));
  });

  testWidgets('시작 시 sync 가 끝난 뒤 목록을 읽는다', (tester) async {
    final syncing = Completer<void>();
    when(alarms.sync).thenAnswer((_) => syncing.future);
    await pump(tester);
    // sync 가 끝나기 전에 읽은 목록(첫 화면용)은 지난 1회성이 아직 켜진 목록일 수 있다.
    clearInteractions(alarms);

    syncing.complete();
    await tester.pumpAndSettle();

    verify(alarms.list).called(1);
  });

  testWidgets('예약 동기화가 실패해도 목록은 읽는다', (tester) async {
    await pump(tester);
    clearInteractions(alarms);
    when(alarms.sync).thenThrow(Exception('scheduler'));

    resume(tester);
    await tester.pumpAndSettle();

    verifyInOrder([alarms.sync, alarms.list]);
  });

  testWidgets('시작할 때 예약 동기화가 실패해도 목록 탭은 빈 목록을 보인다', (tester) async {
    when(alarms.sync).thenThrow(Exception('scheduler'));
    await pump(tester);

    await tester.tap(find.byIcon(Icons.alarm));
    await tester.pumpAndSettle();

    expect(find.text('알람이 없어요'), findsOneWidget);
  });
}
