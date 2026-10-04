import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/core/app.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/app_info/app_info_source.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/domain/settings/repository/settings_repository.dart';
import 'package:walk/domain/walk/entity/health_access.dart';
import 'package:walk/domain/walk/usecase/walk_use_case.dart';
import 'package:walk/presentation/shell/page/main_shell_page.dart';

class _MockAlarmUseCase extends Mock implements AlarmUseCase {}

class _MockWalk extends Mock implements WalkUseCase {}

class _MockRequester extends Mock implements PermissionRequester {}

class _MockAppInfo extends Mock implements AppInfoSource {}

class _MockSettings extends Mock implements SettingsRepository {}

void main() {
  group('themeModeOf', () {
    test('앱 테마 선택을 Flutter ThemeMode 로 옮긴다', () {
      expect(themeModeOf(AppThemeMode.system), ThemeMode.system);
      expect(themeModeOf(AppThemeMode.light), ThemeMode.light);
      expect(themeModeOf(AppThemeMode.dark), ThemeMode.dark);
    });
  });

  group('WalkApp', () {
    late _MockSettings settings;

    setUp(() {
      final alarms = _MockAlarmUseCase();
      final walk = _MockWalk();
      final requester = _MockRequester();
      when(requester.check).thenAnswer((_) async => PermissionStatus.granted);
      when(alarms.list).thenAnswer((_) async => []);
      when(alarms.nextRings).thenAnswer((_) async => {});
      when(alarms.sync).thenAnswer((_) async {});
      when(walk.access).thenAnswer((_) async => HealthAccess.permissionDenied);
      when(() => walk.permissionDeclinedThisSession).thenReturn(false);
      final appInfo = _MockAppInfo();
      when(appInfo.version).thenAnswer((_) async => '1.0.0 (1)');
      settings = _MockSettings();
      getIt
        ..registerSingleton<AlarmUseCase>(alarms)
        ..registerSingleton<WalkUseCase>(walk)
        ..registerSingleton<AppInfoSource>(appInfo)
        ..registerSingleton<SettingsRepository>(settings)
        ..registerSingleton<Clock>(Clock())
        ..registerSingleton<AlarmPermissions>(
          AlarmPermissions(
            notification: requester,
            exactAlarm: requester,
            fullScreenIntent: requester,
          ),
        );
    });
    tearDown(getIt.reset);

    testWidgets('저장된 다크 테마로 첫 프레임부터 뜬다', (tester) async {
      // 기기는 라이트 — 시스템 테마로 떴다면 밝게 보인다.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      when(settings.load).thenReturn(const AppSettings(themeMode: AppThemeMode.dark));

      await tester.pumpWidget(const WalkApp());

      final context = tester.element(find.byType(MainShellPage));
      expect(Theme.of(context).brightness, Brightness.dark);

      await tester.pumpAndSettle();
    });
  });
}
