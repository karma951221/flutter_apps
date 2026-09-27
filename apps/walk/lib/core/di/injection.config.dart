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

import '../../data/walk/health/health_gateway.dart' as _i332;
import '../../data/walk/repository/health_connect_activity_repository.dart'
    as _i1016;
import '../../domain/clock.dart' as _i1053;
import '../../domain/walk/repository/activity_repository.dart' as _i204;
import '../../domain/walk/usecase/walk_use_case.dart' as _i5;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i1053.Clock>(() => _i1053.Clock());
    gh.lazySingleton<_i332.HealthGateway>(() => _i332.HealthPluginGateway());
    gh.lazySingleton<_i204.ActivityRepository>(
      () => _i1016.HealthConnectActivityRepository(gh<_i332.HealthGateway>()),
    );
    gh.lazySingleton<_i5.WalkUseCase>(
      () => _i5.DefaultWalkUseCase(
        gh<_i204.ActivityRepository>(),
        gh<_i1053.Clock>(),
      ),
    );
    return this;
  }
}
