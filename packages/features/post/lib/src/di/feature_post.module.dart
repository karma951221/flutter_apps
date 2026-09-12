// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:core/core.dart' as _i494;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../data/datasource/post_data_source.dart' as _i234;
import '../data/datasource/supabase_post_data_source.dart' as _i192;
import '../data/repository/post_repository_impl.dart' as _i962;
import '../domain/repository/post_repository.dart' as _i90;
import '../domain/usecase/post_use_case.dart' as _i476;
import '../presentation/cubit/post_cubit.dart' as _i895;

class FeaturePostPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i234.PostDataSource>(() => _i192.SupabasePostDataSource(
          gh<_i454.SupabaseClient>(),
          gh<_i494.IdGenerator>(),
          gh<_i494.ImageStorage>(),
        ));
    gh.lazySingleton<_i90.PostRepository>(
        () => _i962.PostRepositoryImpl(gh<_i234.PostDataSource>()));
    gh.lazySingleton<_i476.PostUseCase>(
      () => _i476.DefaultPostUseCase(gh<_i90.PostRepository>()),
      dispose: (i) => i.dispose(),
    );
    gh.factory<_i895.PostCubit>(() => _i895.PostCubit(gh<_i476.PostUseCase>()));
  }
}
