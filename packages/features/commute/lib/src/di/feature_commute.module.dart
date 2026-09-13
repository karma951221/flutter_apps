// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../data/location/location_gateway.dart' as _i47;
import '../data/repository/asset_station_repository.dart' as _i472;
import '../data/repository/fake_transit_route_repository.dart' as _i67;
import '../data/repository/geolocator_location_repository.dart' as _i229;
import '../data/repository/prefs_commute_settings_repository.dart' as _i492;
import '../domain/repository/commute_settings_repository.dart' as _i828;
import '../domain/repository/location_repository.dart' as _i201;
import '../domain/repository/station_repository.dart' as _i91;
import '../domain/repository/transit_route_repository.dart' as _i947;
import '../domain/usecase/commute_use_case.dart' as _i890;
import '../presentation/cubit/commute_settings_cubit.dart' as _i720;
import '../presentation/cubit/station_search_cubit.dart' as _i790;

class FeatureCommutePackageModule extends _i526.MicroPackageModule {
  // initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i47.LocationGateway>(() => _i47.GeolocatorGateway());
    gh.lazySingleton<_i947.TransitRouteRepository>(
      () => _i67.FakeTransitRouteRepository(),
    );
    gh.lazySingleton<_i201.LocationRepository>(
      () => _i229.GeolocatorLocationRepository(gh<_i47.LocationGateway>()),
    );
    gh.lazySingleton<_i91.StationRepository>(
      () => _i472.AssetStationRepository(),
    );
    gh.lazySingleton<_i828.CommuteSettingsRepository>(
      () => _i492.PrefsCommuteSettingsRepository(
        gh<_i460.SharedPreferences>(),
        gh<_i91.StationRepository>(),
      ),
    );
    gh.lazySingleton<_i890.CommuteUseCase>(
      () => _i890.DefaultCommuteUseCase(
        gh<_i947.TransitRouteRepository>(),
        gh<_i201.LocationRepository>(),
        gh<_i91.StationRepository>(),
        gh<_i828.CommuteSettingsRepository>(),
      ),
    );
    gh.factory<_i720.CommuteSettingsCubit>(
      () => _i720.CommuteSettingsCubit(gh<_i890.CommuteUseCase>()),
    );
    gh.factory<_i790.StationSearchCubit>(
      () => _i790.StationSearchCubit(gh<_i890.CommuteUseCase>()),
    );
  }
}
