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
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../data/database/walk_database.dart' as _i563;
import '../../data/dog/drift_dog_repository.dart' as _i40;
import '../../data/location/location_gateway.dart' as _i154;
import '../../data/photo/file_photo_storage.dart' as _i508;
import '../../data/tracking/geolocator_walk_tracker.dart' as _i976;
import '../../data/walk/drift_walk_repository.dart' as _i1020;
import '../../domain/dog/repository/dog_repository.dart' as _i209;
import '../../domain/photo/repository/photo_storage.dart' as _i475;
import '../../domain/tracking/repository/walk_tracker.dart' as _i105;
import '../../domain/walk/repository/walk_repository.dart' as _i612;
import '../../domain/walk/usecase/walk_use_case.dart' as _i5;
import '../../presentation/dog/cubit/dog_edit_cubit.dart' as _i980;
import '../../presentation/dog/cubit/dog_list_cubit.dart' as _i596;
import '../../presentation/feed/cubit/walk_feed_cubit.dart' as _i733;
import '../../presentation/tracking/cubit/active_walk_cubit.dart' as _i143;
import '../../presentation/walk/cubit/walk_detail_cubit.dart' as _i174;
import '../../presentation/walk/cubit/walk_edit_cubit.dart' as _i804;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    await _i494.CorePackageModule().init(gh);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i563.WalkDatabase>(
      () => registerModule.database,
      dispose: _i291.disposeWalkDatabase,
    );
    gh.lazySingleton<_i525.TileProvider>(() => registerModule.tileProvider);
    gh.lazySingleton<_i154.LocationGateway>(() => _i154.GeolocatorGateway());
    await gh.factoryAsync<_i497.Directory>(
      () => registerModule.photosRoot,
      instanceName: 'walkPhotosRoot',
      preResolve: true,
    );
    gh.lazySingleton<_i209.DogRepository>(
      () => _i40.DriftDogRepository(gh<_i563.WalkDatabase>()),
    );
    gh.lazySingleton<_i612.WalkRepository>(
      () => _i1020.DriftWalkRepository(gh<_i563.WalkDatabase>()),
    );
    gh.lazySingleton<_i475.PhotoStorage>(
      () => _i508.FilePhotoStorage(
        gh<_i497.Directory>(instanceName: 'walkPhotosRoot'),
        gh<_i494.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i105.WalkTracker>(
      () => _i976.GeolocatorWalkTracker(gh<_i154.LocationGateway>()),
      dispose: _i976.disposeWalkTracker,
    );
    gh.lazySingleton<_i5.WalkUseCase>(
      () => _i5.DefaultWalkUseCase(
        gh<_i612.WalkRepository>(),
        gh<_i209.DogRepository>(),
        gh<_i105.WalkTracker>(),
        gh<_i475.PhotoStorage>(),
        gh<_i494.IdGenerator>(),
      ),
    );
    gh.factory<_i143.ActiveWalkCubit>(
      () => _i143.ActiveWalkCubit(gh<_i5.WalkUseCase>()),
    );
    gh.factory<_i980.DogEditCubit>(
      () => _i980.DogEditCubit(gh<_i5.WalkUseCase>()),
    );
    gh.factory<_i596.DogListCubit>(
      () => _i596.DogListCubit(gh<_i5.WalkUseCase>()),
    );
    gh.factory<_i733.WalkFeedCubit>(
      () => _i733.WalkFeedCubit(gh<_i5.WalkUseCase>()),
    );
    gh.factory<_i174.WalkDetailCubit>(
      () => _i174.WalkDetailCubit(gh<_i5.WalkUseCase>()),
    );
    gh.factory<_i804.WalkEditCubit>(
      () => _i804.WalkEditCubit(gh<_i5.WalkUseCase>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
