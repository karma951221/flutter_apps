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

import '../../data/health/health_gateway.dart' as _i698;
import '../../data/repository/health_connect_activity_repository.dart'
    as _i1063;
import '../../domain/clock.dart' as _i1053;
import '../../domain/repository/activity_repository.dart' as _i134;
import '../../domain/usecase/walk_use_case.dart' as _i167;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i1053.Clock>(() => _i1053.Clock());
    gh.lazySingleton<_i698.HealthGateway>(() => _i698.HealthPluginGateway());
    gh.lazySingleton<_i134.ActivityRepository>(
      () => _i1063.HealthConnectActivityRepository(gh<_i698.HealthGateway>()),
    );
    gh.lazySingleton<_i167.WalkUseCase>(
      () => _i167.DefaultWalkUseCase(
        gh<_i134.ActivityRepository>(),
        gh<_i1053.Clock>(),
      ),
    );
    return this;
  }
}
