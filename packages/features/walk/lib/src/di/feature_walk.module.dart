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
import '../data/repository/drift_dog_repository.dart' as _i583;
import '../data/repository/drift_walk_repository.dart' as _i739;
import '../data/repository/file_photo_storage.dart' as _i77;
import '../domain/repository/dog_repository.dart' as _i1047;
import '../domain/repository/photo_storage.dart' as _i659;
import '../domain/repository/walk_repository.dart' as _i868;
import '../domain/repository/walk_tracker.dart' as _i890;
import '../domain/usecase/walk_use_case.dart' as _i883;
import 'walk_register_module.dart' as _i911;

class FeatureWalkPackageModule extends _i526.MicroPackageModule {
  // initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) async {
    final walkRegisterModule = _$WalkRegisterModule();
    gh.lazySingleton<_i588.WalkDatabase>(() => walkRegisterModule.database);
    gh.lazySingleton<_i525.TileProvider>(() => walkRegisterModule.tileProvider);
    await gh.factoryAsync<_i497.Directory>(
      () => walkRegisterModule.photosRoot,
      instanceName: 'walkPhotosRoot',
      preResolve: true,
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
  }
}

class _$WalkRegisterModule extends _i911.WalkRegisterModule {}
