// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;
import 'dart:io' as _i497;

import 'package:core/core.dart' as _i494;
import 'package:flutter_map/flutter_map.dart' as _i525;
import 'package:injectable/injectable.dart' as _i526;

import '../data/database/walk_database.dart' as _i588;
import '../data/location/location_gateway.dart' as _i47;
import '../data/repository/drift_dog_repository.dart' as _i583;
import '../data/repository/drift_walk_repository.dart' as _i739;
import '../data/repository/file_photo_storage.dart' as _i77;
import '../data/tracker/geolocator_walk_tracker.dart' as _i460;
import '../domain/repository/dog_repository.dart' as _i1047;
import '../domain/repository/photo_storage.dart' as _i659;
import '../domain/repository/walk_repository.dart' as _i868;
import '../domain/repository/walk_tracker.dart' as _i890;
import '../domain/usecase/walk_use_case.dart' as _i883;
import '../presentation/cubit/active_walk_cubit.dart' as _i794;
import '../presentation/cubit/dog_edit_cubit.dart' as _i641;
import '../presentation/cubit/dog_list_cubit.dart' as _i665;
import '../presentation/cubit/walk_detail_cubit.dart' as _i73;
import '../presentation/cubit/walk_edit_cubit.dart' as _i185;
import '../presentation/cubit/walk_feed_cubit.dart' as _i13;
import 'walk_register_module.dart' as _i911;

class FeatureWalkPackageModule extends _i526.MicroPackageModule {
  // initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) async {
    final walkRegisterModule = _$WalkRegisterModule();
    gh.lazySingleton<_i588.WalkDatabase>(
      () => walkRegisterModule.database,
      dispose: _i911.disposeWalkDatabase,
    );
    gh.lazySingleton<_i525.TileProvider>(() => walkRegisterModule.tileProvider);
    gh.lazySingleton<_i47.LocationGateway>(() => _i47.GeolocatorGateway());
    await gh.factoryAsync<_i497.Directory>(
      () => walkRegisterModule.photosRoot,
      instanceName: 'walkPhotosRoot',
      preResolve: true,
    );
    gh.lazySingleton<_i890.WalkTracker>(
      () => _i460.GeolocatorWalkTracker(gh<_i47.LocationGateway>()),
      dispose: _i460.disposeWalkTracker,
    );
    gh.lazySingleton<_i659.PhotoStorage>(
      () => _i77.FilePhotoStorage(
        gh<_i497.Directory>(instanceName: 'walkPhotosRoot'),
        gh<_i494.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i868.WalkRepository>(
      () => _i739.DriftWalkRepository(gh<_i588.WalkDatabase>()),
    );
    gh.lazySingleton<_i1047.DogRepository>(
      () => _i583.DriftDogRepository(gh<_i588.WalkDatabase>()),
    );
    gh.lazySingleton<_i883.WalkUseCase>(
      () => _i883.DefaultWalkUseCase(
        gh<_i868.WalkRepository>(),
        gh<_i1047.DogRepository>(),
        gh<_i890.WalkTracker>(),
        gh<_i659.PhotoStorage>(),
        gh<_i494.IdGenerator>(),
      ),
    );
    gh.factory<_i641.DogEditCubit>(
      () => _i641.DogEditCubit(gh<_i883.WalkUseCase>()),
    );
    gh.factory<_i665.DogListCubit>(
      () => _i665.DogListCubit(gh<_i883.WalkUseCase>()),
    );
    gh.factory<_i73.WalkDetailCubit>(
      () => _i73.WalkDetailCubit(gh<_i883.WalkUseCase>()),
    );
    gh.factory<_i185.WalkEditCubit>(
      () => _i185.WalkEditCubit(gh<_i883.WalkUseCase>()),
    );
    gh.factory<_i13.WalkFeedCubit>(
      () => _i13.WalkFeedCubit(gh<_i883.WalkUseCase>()),
    );
    gh.factory<_i794.ActiveWalkCubit>(
      () => _i794.ActiveWalkCubit(gh<_i883.WalkUseCase>()),
    );
  }
}

class _$WalkRegisterModule extends _i911.WalkRegisterModule {}
