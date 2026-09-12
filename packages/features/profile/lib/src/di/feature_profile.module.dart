// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:core/core.dart' as _i494;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../data/datasource/profile_data_source.dart' as _i138;
import '../data/datasource/supabase_profile_data_source.dart' as _i482;
import '../data/repository/profile_repository_impl.dart' as _i272;
import '../domain/repository/profile_repository.dart' as _i899;
import '../domain/usecase/profile_use_case.dart' as _i662;
import '../presentation/cubit/profile_cubit.dart' as _i102;

class FeatureProfilePackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i138.ProfileDataSource>(
        () => _i482.SupabaseProfileDataSource(
              gh<_i454.SupabaseClient>(),
              gh<_i494.ImageStorage>(),
            ));
    gh.lazySingleton<_i899.ProfileRepository>(
        () => _i272.ProfileRepositoryImpl(gh<_i138.ProfileDataSource>()));
    gh.lazySingleton<_i662.ProfileUseCase>(
        () => _i662.DefaultProfileUseCase(gh<_i899.ProfileRepository>()));
    gh.factory<_i102.ProfileCubit>(
        () => _i102.ProfileCubit(gh<_i662.ProfileUseCase>()));
  }
}
