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
import 'package:flutter_map/flutter_map.dart' as _i525;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:http/http.dart' as _i519;
import 'package:injectable/injectable.dart' as _i526;
import 'package:local_auth/local_auth.dart' as _i152;
import 'package:location/location.dart' as _i645;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:uuid/uuid.dart' as _i706;

import '../../data/alarm/alarm_permission_module.dart' as _i343;
import '../../data/alarm/archive/drift_ring_archive.dart' as _i380;
import '../../data/alarm/archive/ring_archive_database.dart' as _i869;
import '../../data/alarm/cached_holiday_calendar.dart' as _i93;
import '../../data/alarm/channel_alarm_sound_source.dart' as _i793;
import '../../data/alarm/channel_device_holiday_source.dart' as _i279;
import '../../data/alarm/channel_next_alarm_widget.dart' as _i132;
import '../../data/alarm/channel_reminder_scheduler.dart' as _i553;
import '../../data/alarm/channel_ring_log_source.dart' as _i879;
import '../../data/alarm/holiday_module.dart' as _i183;
import '../../data/alarm/package_alarm_scheduler.dart' as _i238;
import '../../data/alarm/prefs_alarm_repository.dart' as _i1;
import '../../data/chat/anthropic_chat_model.dart' as _i645;
import '../../data/chat/attachment/file_attachment_loader.dart' as _i255;
import '../../data/chat/channel_secure_window.dart' as _i241;
import '../../data/chat/chat_model_registry.dart' as _i1037;
import '../../data/chat/compressed_chat_image_source.dart' as _i957;
import '../../data/chat/database/chat_database.dart' as _i933;
import '../../data/chat/database/drift_chat_history_repository.dart' as _i991;
import '../../data/chat/database/drift_chat_usage_log.dart' as _i1028;
import '../../data/chat/database/drift_wiki_repository.dart' as _i3;
import '../../data/chat/openai_chat_model.dart' as _i442;
import '../../data/chat/prefs_chat_history_settings.dart' as _i433;
import '../../data/chat/prefs_chat_model_catalog.dart' as _i878;
import '../../data/chat/secure_chat_settings.dart' as _i1030;
import '../../data/chat/workspace/file_workspace.dart' as _i373;
import '../../data/commute/geocoding_address_search.dart' as _i667;
import '../../data/commute/odsay_route_finder.dart' as _i132;
import '../../data/commute/prefs_place_repository.dart' as _i265;
import '../../data/commute/prefs_route_preference_repository.dart' as _i644;
import '../../data/commute/seoul_subway_arrival_source.dart' as _i960;
import '../../data/diary/database/diary_database.dart' as _i611;
import '../../data/diary/drift_diary_repository.dart' as _i1049;
import '../../data/diary/media/file_media_store.dart' as _i928;
import '../../data/diary/media/plugin_media_processor.dart' as _i17;
import '../../data/diary/prefs_diary_preferences.dart' as _i383;
import '../../data/location/background_location_access.dart' as _i159;
import '../../data/location/channel_location_recorder.dart' as _i620;
import '../../data/location/database/location_database.dart' as _i121;
import '../../data/location/drift_location_repository.dart' as _i192;
import '../../data/location/prefs_location_preferences.dart' as _i630;
import '../../data/location/prefs_map_style_preferences.dart' as _i478;
import '../../data/lock/channel_screen_lock_settings.dart' as _i952;
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
import '../../domain/alarm/ring_log/ring_archive.dart' as _i361;
import '../../domain/alarm/ring_log/ring_log_source.dart' as _i353;
import '../../domain/alarm/scheduler/alarm_scheduler.dart' as _i702;
import '../../domain/alarm/scheduler/reminder_scheduler.dart' as _i297;
import '../../domain/alarm/sound/alarm_sound_source.dart' as _i344;
import '../../domain/alarm/usecase/alarm_use_case.dart' as _i873;
import '../../domain/alarm/usecase/ring_archiver.dart' as _i626;
import '../../domain/alarm/widget/next_alarm_widget.dart' as _i920;
import '../../domain/chat/attachment/attachment_loader.dart' as _i695;
import '../../domain/chat/chat_history_settings.dart' as _i31;
import '../../domain/chat/chat_model.dart' as _i1004;
import '../../domain/chat/chat_model_catalog.dart' as _i880;
import '../../domain/chat/chat_settings.dart' as _i111;
import '../../domain/chat/chat_trace.dart' as _i825;
import '../../domain/chat/chat_usage_log.dart' as _i520;
import '../../domain/chat/repository/chat_history_repository.dart' as _i752;
import '../../domain/chat/repository/chat_usage_repository.dart' as _i669;
import '../../domain/chat/repository/wiki_repository.dart' as _i624;
import '../../domain/chat/secure_window.dart' as _i555;
import '../../domain/chat/tool/chat_image_source.dart' as _i858;
import '../../domain/chat/tool/life_tools.dart' as _i70;
import '../../domain/chat/tool/wiki_tools.dart' as _i268;
import '../../domain/chat/tool/workspace_tools.dart' as _i215;
import '../../domain/chat/usecase/chat_history_pruner.dart' as _i539;
import '../../domain/chat/usecase/chat_key_verifier.dart' as _i5;
import '../../domain/chat/usecase/chat_model_choice.dart' as _i317;
import '../../domain/chat/usecase/chat_session.dart' as _i502;
import '../../domain/chat/usecase/open_conversation.dart' as _i306;
import '../../domain/chat/usecase/wiki_distiller.dart' as _i870;
import '../../domain/chat/wiki/wiki_context_policy.dart' as _i795;
import '../../domain/chat/workspace/workspace.dart' as _i1060;
import '../../domain/commute/repository/address_search.dart' as _i63;
import '../../domain/commute/repository/place_repository.dart' as _i142;
import '../../domain/commute/repository/route_finder.dart' as _i488;
import '../../domain/commute/repository/route_preference_repository.dart'
    as _i130;
import '../../domain/commute/repository/subway_arrival_source.dart' as _i960;
import '../../domain/commute/usecase/commute_use_case.dart' as _i453;
import '../../domain/diary/location/place_source.dart' as _i693;
import '../../domain/diary/media/media_processor.dart' as _i674;
import '../../domain/diary/media/media_store.dart' as _i870;
import '../../domain/diary/repository/diary_preferences.dart' as _i300;
import '../../domain/diary/repository/diary_repository.dart' as _i122;
import '../../domain/diary/usecase/diary_use_case.dart' as _i567;
import '../../domain/location/recorder/location_recorder.dart' as _i993;
import '../../domain/location/repository/location_preferences.dart' as _i279;
import '../../domain/location/repository/location_repository.dart' as _i379;
import '../../domain/location/repository/map_style_preferences.dart' as _i483;
import '../../domain/location/usecase/location_sync.dart' as _i638;
import '../../domain/location/usecase/stay_namer.dart' as _i673;
import '../../domain/lock/device_auth.dart' as _i439;
import '../../domain/lock/lock_repository.dart' as _i43;
import '../../domain/lock/screen_lock_settings.dart' as _i194;
import '../../domain/settings/repository/settings_repository.dart' as _i91;
import '../../domain/walk/repository/activity_repository.dart' as _i204;
import '../../domain/walk/usecase/walk_use_case.dart' as _i5;
import '../../presentation/chat/attachment/chat_file_picker.dart' as _i211;
import '../../presentation/chat/workspace/workspace_share.dart' as _i835;
import '../../presentation/diary/media_picker.dart' as _i287;
import '../../presentation/lock/media_pick_guard.dart' as _i488;
import '../../presentation/map/cubit/map_style_cubit.dart' as _i58;
import '../../presentation/map/cubit/map_view_cubit.dart' as _i276;
import '../../presentation/map/map_open_requests.dart' as _i98;
import '../config/commute_api_keys.dart' as _i546;
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
    gh.factory<_i525.TileProvider>(() => registerModule.tileProvider);
    gh.lazySingleton<_i494.Clock>(() => registerModule.clock);
    gh.lazySingleton<_i706.Uuid>(() => registerModule.uuid);
    gh.lazySingleton<_i645.LocationGateway>(
      () => registerModule.locationGateway,
    );
    gh.lazySingleton<_i152.LocalAuthentication>(
      () => registerModule.localAuthentication,
    );
    gh.lazySingleton<_i693.PlaceNamer>(() => registerModule.placeNamer);
    gh.lazySingleton<_i519.Client>(() => registerModule.httpClient);
    gh.lazySingleton<_i546.CommuteApiKeys>(() => registerModule.commuteApiKeys);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i825.ChatTrace>(() => registerModule.chatTrace);
    gh.lazySingleton<_i869.RingArchiveDatabase>(
      () => registerModule.ringArchiveDatabase(),
      dispose: _i291.disposeRingArchiveDatabase,
    );
    gh.lazySingleton<_i933.ChatDatabase>(
      () => registerModule.chatDatabase(),
      dispose: _i291.disposeChatDatabase,
    );
    gh.lazySingleton<_i121.LocationDatabase>(
      () => registerModule.locationDatabase(),
      dispose: _i291.disposeLocationDatabase,
    );
    gh.lazySingleton<_i933.AlarmPermissions>(
      () => alarmPermissionModule.alarmPermissions,
    );
    gh.lazySingleton<_i306.OpenConversation>(() => _i306.OpenConversation());
    gh.lazySingleton<_i488.MediaPickGuard>(() => _i488.MediaPickGuard());
    gh.lazySingleton<_i98.MapOpenRequests>(
      () => _i98.MapOpenRequests(),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i494.IdGenerator>(
      () => registerModule.idGenerator(gh<_i706.Uuid>()),
    );
    gh.lazySingleton<_i993.LocationRecorder>(
      () => const _i620.ChannelLocationRecorder(),
    );
    gh.lazySingleton<_i555.SecureWindow>(() => _i241.ChannelSecureWindow());
    gh.lazySingleton<_i361.RingArchive>(
      () => _i380.DriftRingArchive(gh<_i869.RingArchiveDatabase>()),
    );
    gh.lazySingleton<_i194.ScreenLockSettings>(
      () => _i952.ChannelScreenLockSettings(),
    );
    gh.lazySingleton<_i752.ChatHistoryRepository>(
      () => _i991.DriftChatHistoryRepository(
        gh<_i933.ChatDatabase>(),
        gh<_i494.IdGenerator>(),
        gh<_i494.Clock>(),
      ),
    );
    await gh.factoryAsync<_i497.Directory>(
      () => registerModule.diaryRoot,
      instanceName: 'diaryRoot',
      preResolve: true,
    );
    gh.lazySingleton<_i287.MediaPicker>(
      () => _i287.MediaPicker(gh<_i488.MediaPickGuard>()),
    );
    gh.factory<_i211.ChatFilePicker>(
      () => _i211.ChatFilePicker(gh<_i488.MediaPickGuard>()),
    );
    gh.lazySingleton<_i344.AlarmSoundSource>(
      () => _i793.ChannelAlarmSoundSource(),
    );
    gh.lazySingleton<_i297.ReminderScheduler>(
      () => const _i553.ChannelReminderScheduler(),
    );
    gh.lazySingleton<_i695.AttachmentLoader>(
      () => _i255.FileAttachmentLoader(),
    );
    gh.lazySingleton<_i702.AlarmScheduler>(() => _i238.PackageAlarmScheduler());
    gh.lazySingleton<_i111.ChatSettings>(
      () => _i1030.SecureChatSettings(
        gh<_i558.FlutterSecureStorage>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.lazySingleton<_i835.WorkspaceShare>(
      () => _i835.SharePlusWorkspaceShare(gh<_i488.MediaPickGuard>()),
    );
    gh.lazySingleton<_i674.MediaProcessor>(() => _i17.PluginMediaProcessor());
    gh.lazySingleton<_i488.RouteFinder>(
      () => _i132.OdsayRouteFinder(
        gh<_i519.Client>(),
        gh<_i546.CommuteApiKeys>(),
      ),
    );
    gh.lazySingleton<_i332.HealthGateway>(() => _i332.HealthPluginGateway());
    gh.lazySingleton<_i159.BackgroundLocationAccess>(
      () => const _i159.PermissionHandlerBackgroundLocationAccess(),
    );
    gh.lazySingleton<_i63.AddressSearch>(
      () => _i667.GeocodingAddressSearch(gh<_i693.PlaceNamer>()),
    );
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
    gh.lazySingleton<_i645.AnthropicChatModel>(
      () => _i645.AnthropicChatModel(gh<_i519.Client>(), gh<_i825.ChatTrace>()),
    );
    gh.lazySingleton<_i442.OpenAiChatModel>(
      () => _i442.OpenAiChatModel(gh<_i519.Client>(), gh<_i825.ChatTrace>()),
    );
    gh.lazySingleton<_i1004.ChatModelRegistry>(
      () => _i1037.VendorChatModelRegistry(
        gh<_i645.AnthropicChatModel>(),
        gh<_i442.OpenAiChatModel>(),
      ),
    );
    gh.lazySingleton<_i43.LockRepository>(
      () => _i691.PrefsLockRepository(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i300.DiaryPreferences>(
      () => _i383.PrefsDiaryPreferences(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i142.PlaceRepository>(
      () => _i265.PrefsPlaceRepository(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i645.LocationAccess>(
      () => registerModule.locationAccess(gh<_i645.LocationGateway>()),
    );
    gh.lazySingleton<_i880.ChatModelCatalog>(
      () => _i878.PrefsChatModelCatalog(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i693.PlaceSource>(
      () => registerModule.placeSource(
        gh<_i645.LocationAccess>(),
        gh<_i645.LocationGateway>(),
        gh<_i693.PlaceNamer>(),
      ),
    );
    gh.lazySingleton<_i483.MapStylePreferences>(
      () => _i478.PrefsMapStylePreferences(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i379.LocationRepository>(
      () => _i192.DriftLocationRepository(
        gh<_i121.LocationDatabase>(),
        gh<_i494.Clock>(),
      ),
    );
    gh.lazySingleton<_i960.SubwayArrivalSource>(
      () => _i960.SeoulSubwayArrivalSource(
        gh<_i519.Client>(),
        gh<_i546.CommuteApiKeys>(),
        gh<_i494.Clock>(),
      ),
    );
    gh.lazySingleton<_i961.HolidayCalendar>(
      () => holidayModule.holidayCalendar(gh<_i93.CachedHolidayCalendar>()),
    );
    gh.lazySingleton<_i961.HolidayRefresher>(
      () => holidayModule.holidayRefresher(gh<_i93.CachedHolidayCalendar>()),
    );
    gh.factory<_i673.StayNamer>(
      () => _i673.StayNamer(
        gh<_i379.LocationRepository>(),
        gh<_i693.PlaceNamer>(),
      ),
    );
    gh.lazySingleton<_i1060.Workspace>(
      () => _i373.FileWorkspace.standard(gh<_i494.Clock>()),
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
    gh.lazySingleton<_i31.ChatHistorySettings>(
      () => _i433.PrefsChatHistorySettings(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i130.RoutePreferenceRepository>(
      () => _i644.PrefsRoutePreferenceRepository(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i279.LocationPreferences>(
      () => _i630.PrefsLocationPreferences(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i669.ChatUsageRepository>(
      () => _i1028.DriftChatUsageRepository(gh<_i933.ChatDatabase>()),
    );
    gh.lazySingleton<_i296.AlarmRepository>(
      () => _i1.PrefsAlarmRepository(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i520.ChatUsageLog>(
      () => _i1028.DriftChatUsageLog(gh<_i933.ChatDatabase>()),
    );
    gh.lazySingleton<_i624.WikiRepository>(
      () =>
          _i3.DriftWikiRepository(gh<_i933.ChatDatabase>(), gh<_i494.Clock>()),
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
    gh.lazySingleton<_i453.CommuteUseCase>(
      () => _i453.CommuteUseCase(
        gh<_i142.PlaceRepository>(),
        gh<_i130.RoutePreferenceRepository>(),
        gh<_i488.RouteFinder>(),
        gh<_i960.SubwayArrivalSource>(),
        gh<_i546.CommuteApiKeys>(),
        gh<_i494.Clock>(),
      ),
    );
    gh.lazySingleton<_i5.ChatKeyVerifier>(
      () => _i5.ChatKeyVerifier(
        gh<_i1004.ChatModelRegistry>(),
        gh<_i111.ChatSettings>(),
      ),
    );
    gh.lazySingleton<_i795.WikiContextPolicy>(
      () => _i795.IndexAndReadPolicy(
        gh<_i624.WikiRepository>(),
        gh<_i31.ChatHistorySettings>(),
      ),
    );
    gh.lazySingleton<_i858.ChatImageSource>(
      () => _i957.CompressedChatImageSource(gh<_i870.MediaStore>()),
    );
    gh.factory<_i638.LocationSync>(
      () => _i638.LocationSync(
        gh<_i993.LocationRecorder>(),
        gh<_i379.LocationRepository>(),
        gh<_i279.LocationPreferences>(),
        gh<_i494.Clock>(),
      ),
    );
    gh.lazySingleton<_i58.MapStyleCubit>(
      () => _i58.MapStyleCubit(gh<_i483.MapStylePreferences>()),
      dispose: (i) => i.close(),
    );
    gh.lazySingleton<_i122.DiaryRepository>(
      () => _i1049.DriftDiaryRepository(
        gh<_i611.DiaryDatabase>(),
        gh<_i494.IdGenerator>(),
        gh<_i494.Clock>(),
      ),
    );
    gh.lazySingleton<_i539.ChatHistoryPruner>(
      () => _i539.ChatHistoryPruner(
        gh<_i752.ChatHistoryRepository>(),
        gh<_i669.ChatUsageRepository>(),
        gh<_i31.ChatHistorySettings>(),
        gh<_i306.OpenConversation>(),
        gh<_i494.Clock>(),
      ),
    );
    gh.lazySingleton<_i215.WorkspaceTools>(
      () => _i215.WorkspaceTools(
        gh<_i1060.Workspace>(),
        gh<_i695.AttachmentLoader>(),
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
    gh.factory<_i276.MapViewCubit>(
      () => _i276.MapViewCubit(
        gh<_i379.LocationRepository>(),
        gh<_i122.DiaryRepository>(),
        gh<_i638.LocationSync>(),
        gh<_i673.StayNamer>(),
        gh<_i993.LocationRecorder>(),
        gh<_i494.Clock>(),
      ),
    );
    gh.lazySingleton<_i317.ChatModelChoice>(
      () => _i317.ChatModelChoice(
        gh<_i111.ChatSettings>(),
        gh<_i880.ChatModelCatalog>(),
        gh<_i5.ChatKeyVerifier>(),
        gh<_i494.Clock>(),
      ),
    );
    gh.lazySingleton<_i268.WikiTools>(
      () => _i268.WikiTools(
        gh<_i624.WikiRepository>(),
        gh<_i122.DiaryRepository>(),
      ),
    );
    gh.lazySingleton<_i626.RingArchiver>(
      () => _i626.RingArchiver(
        gh<_i353.RingLogSource>(),
        gh<_i361.RingArchive>(),
        gh<_i873.AlarmUseCase>(),
      ),
    );
    gh.lazySingleton<_i870.WikiDistiller>(
      () => _i870.WikiDistiller(
        gh<_i1004.ChatModelRegistry>(),
        gh<_i111.ChatSettings>(),
        gh<_i317.ChatModelChoice>(),
        gh<_i31.ChatHistorySettings>(),
        gh<_i752.ChatHistoryRepository>(),
        gh<_i624.WikiRepository>(),
        gh<_i268.WikiTools>(),
        gh<_i122.DiaryRepository>(),
        gh<_i520.ChatUsageLog>(),
        gh<_i494.IdGenerator>(),
        gh<_i494.Clock>(),
      ),
    );
    gh.lazySingleton<_i70.LifeTools>(
      () => _i70.LifeTools(
        gh<_i122.DiaryRepository>(),
        gh<_i204.ActivityRepository>(),
        gh<_i626.RingArchiver>(),
        gh<_i361.RingArchive>(),
        gh<_i858.ChatImageSource>(),
      ),
    );
    gh.lazySingleton<_i502.ChatSession>(
      () => _i502.ChatSession(
        gh<_i1004.ChatModelRegistry>(),
        gh<_i70.LifeTools>(),
        gh<_i111.ChatSettings>(),
        gh<_i317.ChatModelChoice>(),
        gh<_i494.Clock>(),
        gh<_i520.ChatUsageLog>(),
        gh<_i494.IdGenerator>(),
        gh<_i825.ChatTrace>(),
        gh<_i795.WikiContextPolicy>(),
        gh<_i268.WikiTools>(),
        gh<_i215.WorkspaceTools>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}

class _$AlarmPermissionModule extends _i343.AlarmPermissionModule {}

class _$HolidayModule extends _i183.HolidayModule {}
