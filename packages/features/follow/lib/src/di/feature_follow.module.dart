// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../data/datasource/follow_data_source.dart' as _i724;
import '../data/datasource/supabase_follow_data_source.dart' as _i605;
import '../data/repository/follow_repository_impl.dart' as _i193;
import '../domain/repository/follow_repository.dart' as _i911;
import '../domain/usecase/follow_use_case.dart' as _i116;
import '../presentation/cubit/follow_action_cubit.dart' as _i141;
import '../presentation/cubit/follow_list_cubit.dart' as _i788;

class FeatureFollowPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i724.FollowDataSource>(
        () => _i605.SupabaseFollowDataSource(gh<_i454.SupabaseClient>()));
    gh.lazySingleton<_i911.FollowRepository>(
        () => _i193.FollowRepositoryImpl(gh<_i724.FollowDataSource>()));
    gh.lazySingleton<_i116.FollowUseCase>(
        () => _i116.DefaultFollowUseCase(gh<_i911.FollowRepository>()));
    gh.factory<_i141.FollowActionCubit>(
        () => _i141.FollowActionCubit(gh<_i116.FollowUseCase>()));
    gh.factory<_i788.FollowListCubit>(
        () => _i788.FollowListCubit(gh<_i116.FollowUseCase>()));
  }
}
