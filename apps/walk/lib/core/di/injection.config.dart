// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:io' as _i497;

import 'package:core/core.dart' as _i494;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:local_auth/local_auth.dart' as _i152;
import 'package:location/location.dart' as _i645;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:uuid/uuid.dart' as _i706;

import '../../data/alarm/alarm_permission_module.dart' as _i343;
import '../../data/alarm/cached_holiday_calendar.dart' as _i93;
import '../../data/alarm/channel_alarm_sound_source.dart' as _i793;
import '../../data/alarm/channel_device_holiday_source.dart' as _i279;
import '../../data/alarm/channel_next_alarm_widget.dart' as _i132;
import '../../data/alarm/channel_reminder_scheduler.dart' as _i553;
import '../../data/alarm/channel_ring_log_source.dart' as _i879;
import '../../data/alarm/holiday_module.dart' as _i183;
import '../../data/alarm/package_alarm_scheduler.dart' as _i238;
import '../../data/alarm/prefs_alarm_repository.dart' as _i1;
import '../../data/diary/database/diary_database.dart' as _i611;
import '../../data/diary/drift_diary_repository.dart' as _i1049;
import '../../data/diary/media/file_media_store.dart' as _i928;
import '../../data/diary/media/plugin_media_processor.dart' as _i17;
import '../../data/diary/prefs_diary_preferences.dart' as _i383;
import '../../data/lock/local_auth_device_auth.dart' as _i982;
import '../../data/lock/prefs_lock_repository.dart' as _i691;
import '../../data/settings/prefs_settings_repository.dart' as _i724;
import '../../data/walk/health/health_gateway.dart' as _i332;
import '../../data/walk/repository/health_connect_activity_repository.dart'
    as _i1016;
import '../../domain/alarm/holiday/device_holiday_source.dart' as _i77;
import '../../domain/alarm/holiday/holiday_calendar.dart' as _i961;
import '../../domain/alarm/holiday/holiday_calendar_access.dart' as _i227;
import '../../domain/alarm/permission/alarm_permissions.dart' as _i933;
import '../../domain/alarm/repository/alarm_repository.dart' as _i296;
import '../../domain/alarm/ring_log/ring_log_source.dart' as _i353;
import '../../domain/alarm/scheduler/alarm_scheduler.dart' as _i702;
import '../../domain/alarm/scheduler/reminder_scheduler.dart' as _i297;
import '../../domain/alarm/sound/alarm_sound_source.dart' as _i344;
import '../../domain/alarm/usecase/alarm_use_case.dart' as _i873;
import '../../domain/alarm/widget/next_alarm_widget.dart' as _i920;
import '../../domain/diary/location/place_source.dart' as _i693;
import '../../domain/diary/media/media_processor.dart' as _i674;
import '../../domain/diary/media/media_store.dart' as _i870;
import '../../domain/diary/repository/diary_preferences.dart' as _i300;
import '../../domain/diary/repository/diary_repository.dart' as _i122;
import '../../domain/diary/usecase/diary_use_case.dart' as _i567;
import '../../domain/lock/device_auth.dart' as _i439;
import '../../domain/lock/lock_repository.dart' as _i43;
import '../../domain/settings/repository/settings_repository.dart' as _i91;
import '../../domain/walk/repository/activity_repository.dart' as _i204;
import '../../domain/walk/usecase/walk_use_case.dart' as _i5;
import '../../presentation/diary/media_picker.dart' as _i287;
import '../../presentation/lock/media_pick_guard.dart' as _i488;
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
    final holidayModule = _$HolidayModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i494.Clock>(() => registerModule.clock);
    gh.lazySingleton<_i706.Uuid>(() => registerModule.uuid);
    gh.lazySingleton<_i645.LocationGateway>(
      () => registerModule.locationGateway,
    );
    gh.lazySingleton<_i152.LocalAuthentication>(
      () => registerModule.localAuthentication,
    );
    gh.lazySingleton<_i693.PlaceNamer>(() => registerModule.placeNamer);
    gh.lazySingleton<_i933.AlarmPermissions>(
      () => alarmPermissionModule.alarmPermissions,
    );
    gh.lazySingleton<_i488.MediaPickGuard>(() => _i488.MediaPickGuard());
    gh.lazySingleton<_i494.IdGenerator>(
      () => registerModule.idGenerator(gh<_i706.Uuid>()),
    );
    await gh.factoryAsync<_i497.Directory>(
      () => registerModule.diaryRoot,
      instanceName: 'diaryRoot',
      preResolve: true,
    );
    gh.lazySingleton<_i287.MediaPicker>(
      () => _i287.MediaPicker(gh<_i488.MediaPickGuard>()),
    );
    gh.lazySingleton<_i344.AlarmSoundSource>(
      () => _i793.ChannelAlarmSoundSource(),
    );
    gh.lazySingleton<_i297.ReminderScheduler>(
      () => const _i553.ChannelReminderScheduler(),
    );
    gh.lazySingleton<_i702.AlarmScheduler>(() => _i238.PackageAlarmScheduler());
    gh.lazySingleton<_i674.MediaProcessor>(() => _i17.PluginMediaProcessor());
    gh.lazySingleton<_i332.HealthGateway>(() => _i332.HealthPluginGateway());
    gh.lazySingleton<_i77.DeviceHolidaySource>(
      () => const _i279.ChannelDeviceHolidaySource(),
    );
    gh.lazySingleton<_i93.CachedHolidayCalendar>(
      () => _i93.CachedHolidayCalendar(
        gh<_i460.SharedPreferences>(),
        gh<_i77.DeviceHolidaySource>(),
        gh<_i494.Clock>(),
      ),
    );
    gh.lazySingleton<_i204.ActivityRepository>(
      () => _i1016.HealthConnectActivityRepository(gh<_i332.HealthGateway>()),
    );
    gh.lazySingleton<_i920.NextAlarmWidget>(
      () => const _i132.ChannelNextAlarmWidget(),
    );
    gh.lazySingleton<_i353.RingLogSource>(
      () => const _i879.ChannelRingLogSource(),
    );
    gh.lazySingleton<_i91.SettingsRepository>(
      () => _i724.PrefsSettingsRepository(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i43.LockRepository>(
      () => _i691.PrefsLockRepository(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i300.DiaryPreferences>(
      () => _i383.PrefsDiaryPreferences(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i645.LocationAccess>(
      () => registerModule.locationAccess(gh<_i645.LocationGateway>()),
    );
    gh.lazySingleton<_i693.PlaceSource>(
      () => registerModule.placeSource(
        gh<_i645.LocationAccess>(),
        gh<_i645.LocationGateway>(),
        gh<_i693.PlaceNamer>(),
      ),
    );
    gh.lazySingleton<_i961.HolidayCalendar>(
      () => holidayModule.holidayCalendar(gh<_i93.CachedHolidayCalendar>()),
    );
    gh.lazySingleton<_i961.HolidayRefresher>(
      () => holidayModule.holidayRefresher(gh<_i93.CachedHolidayCalendar>()),
    );
    gh.lazySingleton<_i611.DiaryDatabase>(
      () => registerModule.diaryDatabase(gh<_i494.Clock>()),
      dispose: _i291.disposeDiaryDatabase,
    );
    gh.lazySingleton<_i227.HolidayCalendarAccess>(
      () => holidayModule.holidayCalendarAccess(
        gh<_i93.CachedHolidayCalendar>(),
        gh<_i91.SettingsRepository>(),
      ),
    );
    gh.lazySingleton<_i296.AlarmRepository>(
      () => _i1.PrefsAlarmRepository(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i439.DeviceAuth>(
      () => _i982.LocalAuthDeviceAuth(gh<_i152.LocalAuthentication>()),
    );
    gh.lazySingleton<_i870.MediaStore>(
      () => _i928.FileMediaStore(
        gh<_i497.Directory>(instanceName: 'diaryRoot'),
        gh<_i494.IdGenerator>(),
        gh<_i674.MediaProcessor>(),
      ),
    );
    gh.lazySingleton<_i5.WalkUseCase>(
      () => _i5.DefaultWalkUseCase(
        gh<_i204.ActivityRepository>(),
        gh<_i494.Clock>(),
      ),
    );
    gh.lazySingleton<_i122.DiaryRepository>(
      () => _i1049.DriftDiaryRepository(
        gh<_i611.DiaryDatabase>(),
        gh<_i494.IdGenerator>(),
        gh<_i494.Clock>(),
      ),
    );
    gh.lazySingleton<_i873.AlarmUseCase>(
      () => _i873.DefaultAlarmUseCase(
        gh<_i296.AlarmRepository>(),
        gh<_i702.AlarmScheduler>(),
        gh<_i494.Clock>(),
        gh<_i297.ReminderScheduler>(),
        gh<_i961.HolidayCalendar>(),
        gh<_i91.SettingsRepository>(),
        gh<_i353.RingLogSource>(),
        gh<_i920.NextAlarmWidget>(),
      ),
    );
    gh.lazySingleton<_i567.DiaryUseCase>(
      () => _i567.DiaryUseCase(
        gh<_i122.DiaryRepository>(),
        gh<_i870.MediaStore>(),
        gh<_i693.PlaceSource>(),
        gh<_i300.DiaryPreferences>(),
        gh<_i494.Clock>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}

class _$AlarmPermissionModule extends _i343.AlarmPermissionModule {}

class _$HolidayModule extends _i183.HolidayModule {}
