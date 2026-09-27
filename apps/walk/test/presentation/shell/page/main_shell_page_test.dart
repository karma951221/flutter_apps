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

  setUp(() {
    alarms = _MockAlarmUseCase();
    walk = _MockWalk();
    final notification = _MockRequester();
    final exactAlarm = _MockRequester();
    final fullScreen = _MockRequester();
    for (final r in [notification, exactAlarm, fullScreen]) {
      when(r.check).thenAnswer((_) async => PermissionStatus.granted);
    }
    when(alarms.list).thenAnswer((_) async => []);
    when(alarms.next).thenAnswer((_) async => null);
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
}
