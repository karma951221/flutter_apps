// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:core/core.dart' as _i494;
import 'package:injectable/injectable.dart' as _i526;

import '../domain/repository/dog_repository.dart' as _i1047;
import '../domain/repository/photo_storage.dart' as _i659;
import '../domain/repository/walk_repository.dart' as _i868;
import '../domain/repository/walk_tracker.dart' as _i890;
import '../domain/usecase/walk_use_case.dart' as _i883;

class FeatureWalkPackageModule extends _i526.MicroPackageModule {
  // initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
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
