// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../data/alarm/alarm_permission_module.dart' as _i343;
import '../../data/alarm/package_alarm_scheduler.dart' as _i238;
import '../../data/alarm/prefs_alarm_repository.dart' as _i1;
import '../../data/app_info/app_info_source.dart' as _i527;
import '../../data/settings/prefs_settings_repository.dart' as _i724;
import '../../data/walk/health/health_gateway.dart' as _i332;
import '../../data/walk/repository/health_connect_activity_repository.dart'
    as _i1016;
import '../../domain/alarm/permission/alarm_permissions.dart' as _i933;
import '../../domain/alarm/repository/alarm_repository.dart' as _i296;
import '../../domain/alarm/scheduler/alarm_scheduler.dart' as _i702;
import '../../domain/alarm/usecase/alarm_use_case.dart' as _i873;
import '../../domain/app_info/app_info_source.dart' as _i811;
import '../../domain/clock.dart' as _i1053;
import '../../domain/settings/repository/settings_repository.dart' as _i91;
import '../../domain/walk/repository/activity_repository.dart' as _i204;
import '../../domain/walk/usecase/walk_use_case.dart' as _i5;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    final alarmPermissionModule = _$AlarmPermissionModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i933.AlarmPermissions>(
      () => alarmPermissionModule.alarmPermissions,
    );
    gh.lazySingleton<_i1053.Clock>(() => _i1053.Clock());
    gh.lazySingleton<_i702.AlarmScheduler>(() => _i238.PackageAlarmScheduler());
    gh.lazySingleton<_i332.HealthGateway>(() => _i332.HealthPluginGateway());
    gh.lazySingleton<_i204.ActivityRepository>(
      () => _i1016.HealthConnectActivityRepository(gh<_i332.HealthGateway>()),
    );
    gh.lazySingleton<_i811.AppInfoSource>(
      () => _i527.PackageInfoAppInfoSource(),
    );
    gh.lazySingleton<_i91.SettingsRepository>(
      () => _i724.PrefsSettingsRepository(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i5.WalkUseCase>(
      () => _i5.DefaultWalkUseCase(
        gh<_i204.ActivityRepository>(),
        gh<_i1053.Clock>(),
      ),
    );
    gh.lazySingleton<_i296.AlarmRepository>(
      () => _i1.PrefsAlarmRepository(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i873.AlarmUseCase>(
      () => _i873.DefaultAlarmUseCase(
        gh<_i296.AlarmRepository>(),
        gh<_i702.AlarmScheduler>(),
        gh<_i1053.Clock>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}

class _$AlarmPermissionModule extends _i343.AlarmPermissionModule {}
