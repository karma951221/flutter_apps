// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:injectable/injectable.dart' as _i526;

import '../domain/repository/commute_settings_repository.dart' as _i828;
import '../domain/repository/location_repository.dart' as _i201;
import '../domain/repository/station_repository.dart' as _i91;
import '../domain/repository/transit_route_repository.dart' as _i947;
import '../domain/usecase/commute_use_case.dart' as _i890;

class FeatureCommutePackageModule extends _i526.MicroPackageModule {
  // initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i890.CommuteUseCase>(
      () => _i890.DefaultCommuteUseCase(
        gh<_i947.TransitRouteRepository>(),
        gh<_i201.LocationRepository>(),
        gh<_i91.StationRepository>(),
        gh<_i828.CommuteSettingsRepository>(),
      ),
    );
  }
}
