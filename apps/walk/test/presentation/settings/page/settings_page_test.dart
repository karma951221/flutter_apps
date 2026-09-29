import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/app_info/app_info_source.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/domain/settings/repository/settings_repository.dart';
import 'package:walk/domain/walk/entity/health_access.dart';
import 'package:walk/domain/walk/usecase/walk_use_case.dart';
import 'package:walk/presentation/settings/cubit/settings_permissions_cubit.dart';
import 'package:walk/presentation/settings/cubit/theme_cubit.dart';
import 'package:walk/presentation/settings/page/settings_page.dart';

class _MockRequester extends Mock implements PermissionRequester {}

class _MockWalk extends Mock implements WalkUseCase {}

class _MockSettings extends Mock implements SettingsRepository {}

class _MockAppInfo extends Mock implements AppInfoSource {}

void main() {
  late _MockRequester notification;
  late _MockRequester exactAlarm;
  late _MockRequester fullScreen;
  late _MockWalk walk;
  late _MockSettings settings;
  late SettingsPermissionsCubit permissions;
  late ThemeCubit theme;

  setUpAll(() => registerFallbackValue(const AppSettings()));
  setUp(() {
    notification = _MockRequester();
    exactAlarm = _MockRequester();
    fullScreen = _MockRequester();
    walk = _MockWalk();
    settings = _MockSettings();
    when(notification.check).thenAnswer((_) async => PermissionStatus.granted);
    when(exactAlarm.check).thenAnswer((_) async => PermissionStatus.denied);
    when(fullScreen.check).thenAnswer((_) async => PermissionStatus.granted);
    when(fullScreen.openSettings).thenAnswer((_) async {});
    when(walk.access).thenAnswer((_) async => HealthAccess.notInstalled);
    when(settings.load).thenReturn(const AppSettings());
    when(() => settings.save(any())).thenAnswer((_) async {});
    final appInfo = _MockAppInfo();
    when(appInfo.version).thenAnswer((_) async => '1.0.0 (1)');
    getIt.registerSingleton<AppInfoSource>(appInfo);
    permissions = SettingsPermissionsCubit(
      AlarmPermissions(
        notification: notification,
        exactAlarm: exactAlarm,
        fullScreenIntent: fullScreen,
      ),
      walk,
    );
    theme = ThemeCubit(settings);
  });
  tearDown(() async {
    await permissions.close();
    await theme.close();
    await getIt.reset();
  });

  Future<void> pump(WidgetTester tester, {bool checked = true}) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    if (checked) await permissions.check();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: permissions),
          BlocProvider.value(value: theme),
        ],
        child: BlocBuilder<ThemeCubit, AppThemeMode>(
          builder: (context, mode) => MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: mode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light,
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('권한 상태 · 버전 · 안내를 보인다', (tester) async {
    await pump(tester);

    expect(find.text('허용됨'), findsNWidgets(2));
    expect(find.text('허용 필요 ›'), findsOneWidget);
    expect(find.text('설치 필요 ›'), findsOneWidget);
    expect(find.text('1.0.0 (1)'), findsOneWidget);
    expect(find.text('앱을 14일 넘게 열지 않으면 반복 알람이 멈출 수 있어요.'), findsOneWidget);
  });

  testWidgets('권한 행을 누르면 해당 설정을 연다', (tester) async {
    await pump(tester);

    await tester.tap(find.text('전체 화면 알림'));
    verify(fullScreen.openSettings).called(1);
  });

  testWidgets('테마를 고르면 즉시 반영하고 저장한다', (tester) async {
    await pump(tester);
    expect(Theme.of(tester.element(find.byType(SettingsPage))).brightness, Brightness.light);

    await tester.tap(find.text('다크'));
    await tester.pumpAndSettle();

    expect(theme.state, AppThemeMode.dark);
    verify(() => settings.save(const AppSettings(themeMode: AppThemeMode.dark))).called(1);
    expect(Theme.of(tester.element(find.byType(SettingsPage))).brightness, Brightness.dark);
  });

  testWidgets('확인 중(null)이면 상태 문구를 비운다', (tester) async {
    await pump(tester, checked: false);

    expect(find.text('알림'), findsOneWidget);
    for (final label in ['허용됨', '허용 필요 ›', '설치 필요 ›', '업데이트 필요 ›']) {
      expect(find.text(label), findsNothing, reason: label);
    }
  });

  testWidgets('알림 행: 아직 물을 수 있으면(denied) 다시 묻고 상태를 다시 읽는다', (tester) async {
    when(notification.check).thenAnswer((_) async => PermissionStatus.denied);
    when(notification.requestAgain).thenAnswer((_) async {
      when(notification.check).thenAnswer((_) async => PermissionStatus.granted);
      return PermissionStatus.granted;
    });
    await pump(tester);
    expect(find.text('허용 필요 ›'), findsNWidgets(2));

    await tester.tap(find.text('알림'));
    await tester.pumpAndSettle();

    verify(notification.requestAgain).called(1);
    verifyNever(notification.openSettings);
    // 알림은 허용됨으로 바뀌고 정확한 알람만 허용 필요.
    expect(find.text('허용 필요 ›'), findsOneWidget);
  });

  testWidgets('알림 행: 이미 허용이면 앱 설정을 연다', (tester) async {
    when(notification.openSettings).thenAnswer((_) async {});
    await pump(tester);

    await tester.tap(find.text('알림'));
    await tester.pumpAndSettle();

    verify(notification.openSettings).called(1);
    verifyNever(notification.requestAgain);
  });

  testWidgets('정확한 알람 행을 누르면 정확한 알람 설정을 연다', (tester) async {
    when(exactAlarm.openSettings).thenAnswer((_) async {});
    await pump(tester);

    await tester.tap(find.text('정확한 알람'));
    await tester.pumpAndSettle();

    verify(exactAlarm.openSettings).called(1);
  });

  testWidgets('Health Connect 행: 설치가 필요하면 설치 화면을 연다', (tester) async {
    when(walk.openInstall).thenAnswer((_) async {});
    await pump(tester);

    await tester.tap(find.text('Health Connect'));
    await tester.pumpAndSettle();

    verify(walk.openInstall).called(1);
  });

  testWidgets('오픈소스 라이선스 행은 LicensePage 를 연다', (tester) async {
    await pump(tester);

    await tester.tap(find.text('오픈소스 라이선스'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });
}
