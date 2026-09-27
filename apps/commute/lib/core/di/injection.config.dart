// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:core/core.dart' as _i494;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../data/location/location_gateway.dart' as _i154;
import '../../data/repository/asset_station_repository.dart' as _i979;
import '../../data/repository/fake_transit_route_repository.dart' as _i932;
import '../../data/repository/geolocator_location_repository.dart' as _i41;
import '../../data/repository/prefs_commute_settings_repository.dart' as _i1028;
import '../../domain/repository/commute_settings_repository.dart' as _i404;
import '../../domain/repository/location_repository.dart' as _i773;
import '../../domain/repository/station_repository.dart' as _i607;
import '../../domain/repository/transit_route_repository.dart' as _i1039;
import '../../domain/usecase/commute_use_case.dart' as _i365;
import '../../presentation/cubit/commute_home_cubit.dart' as _i720;
import '../../presentation/cubit/commute_settings_cubit.dart' as _i588;
import '../../presentation/cubit/station_search_cubit.dart' as _i656;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    await _i494.CorePackageModule().init(gh);
    gh.lazySingleton<_i1039.TransitRouteRepository>(
      () => _i932.FakeTransitRouteRepository(),
    );
    gh.lazySingleton<_i154.LocationGateway>(() => _i154.GeolocatorGateway());
    gh.lazySingleton<_i607.StationRepository>(
      () => _i979.AssetStationRepository(),
    );
    gh.lazySingleton<_i773.LocationRepository>(
      () => _i41.GeolocatorLocationRepository(gh<_i154.LocationGateway>()),
    );
    gh.lazySingleton<_i404.CommuteSettingsRepository>(
      () => _i1028.PrefsCommuteSettingsRepository(
        gh<_i460.SharedPreferences>(),
        gh<_i607.StationRepository>(),
      ),
    );
    gh.lazySingleton<_i365.CommuteUseCase>(
      () => _i365.DefaultCommuteUseCase(
        gh<_i1039.TransitRouteRepository>(),
        gh<_i773.LocationRepository>(),
        gh<_i607.StationRepository>(),
        gh<_i404.CommuteSettingsRepository>(),
      ),
    );
    gh.factory<_i720.CommuteHomeCubit>(
      () => _i720.CommuteHomeCubit(gh<_i365.CommuteUseCase>()),
    );
    gh.factory<_i588.CommuteSettingsCubit>(
      () => _i588.CommuteSettingsCubit(gh<_i365.CommuteUseCase>()),
    );
    gh.factory<_i656.StationSearchCubit>(
      () => _i656.StationSearchCubit(gh<_i365.CommuteUseCase>()),
    );
    return this;
  }
}
