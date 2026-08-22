// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../../features/auth/data/datasource/auth_data_source.dart' as _i692;
import '../../features/auth/data/datasource/supabase_auth_data_source.dart'
    as _i87;
import '../../features/auth/data/repository/supabase_auth_repository.dart'
    as _i971;
import '../../features/auth/domain/repository/auth_repository.dart' as _i961;
import '../../features/auth/domain/usecase/auth_use_case.dart' as _i176;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i797;
import '../../features/auth/presentation/cubit/password_reset_cubit.dart'
    as _i271;
import '../../features/auth/presentation/cubit/sign_in_cubit.dart' as _i329;
import '../../features/auth/presentation/cubit/sign_up_cubit.dart' as _i102;
import '../../features/feed/data/datasource/feed_data_source.dart' as _i514;
import '../../features/feed/data/datasource/supabase_feed_data_source.dart'
    as _i402;
import '../../features/feed/data/repository/feed_repository_impl.dart' as _i749;
import '../../features/feed/domain/repository/feed_repository.dart' as _i898;
import '../../features/feed/domain/usecase/feed_use_case.dart' as _i1009;
import '../../features/feed/presentation/cubit/feed_cubit.dart' as _i58;
import '../../features/profile/data/datasource/profile_data_source.dart'
    as _i986;
import '../../features/profile/data/datasource/supabase_profile_data_source.dart'
    as _i787;
import '../../features/profile/data/repository/profile_repository_impl.dart'
    as _i309;
import '../../features/profile/domain/repository/profile_repository.dart'
    as _i364;
import '../../features/profile/domain/usecase/profile_use_case.dart' as _i408;
import '../../features/profile/presentation/cubit/profile_cubit.dart' as _i36;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i454.SupabaseClient>(() => registerModule.supabaseClient);
    gh.lazySingleton<_i514.FeedDataSource>(
      () => _i402.SupabaseFeedDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i986.ProfileDataSource>(
      () => _i787.SupabaseProfileDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i692.AuthDataSource>(
      () => _i87.SupabaseAuthDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i898.FeedRepository>(
      () => _i749.FeedRepositoryImpl(gh<_i514.FeedDataSource>()),
    );
    gh.lazySingleton<_i961.AuthRepository>(
      () => _i971.SupabaseAuthRepository(gh<_i692.AuthDataSource>()),
    );
    gh.lazySingleton<_i1009.FeedUseCase>(
      () => _i1009.DefaultFeedUseCase(gh<_i898.FeedRepository>()),
    );
    gh.lazySingleton<_i364.ProfileRepository>(
      () => _i309.ProfileRepositoryImpl(gh<_i986.ProfileDataSource>()),
    );
    gh.lazySingleton<_i176.AuthUseCase>(
      () => _i176.DefaultAuthUseCase(gh<_i961.AuthRepository>()),
    );
    gh.factory<_i797.AuthBloc>(() => _i797.AuthBloc(gh<_i176.AuthUseCase>()));
    gh.factory<_i271.PasswordResetCubit>(
      () => _i271.PasswordResetCubit(gh<_i176.AuthUseCase>()),
    );
    gh.factory<_i329.SignInCubit>(
      () => _i329.SignInCubit(gh<_i176.AuthUseCase>()),
    );
    gh.factory<_i102.SignUpCubit>(
      () => _i102.SignUpCubit(gh<_i176.AuthUseCase>()),
    );
    gh.factory<_i58.FeedCubit>(() => _i58.FeedCubit(gh<_i1009.FeedUseCase>()));
    gh.lazySingleton<_i408.ProfileUseCase>(
      () => _i408.DefaultProfileUseCase(gh<_i364.ProfileRepository>()),
    );
    gh.factory<_i36.ProfileCubit>(
      () => _i36.ProfileCubit(gh<_i408.ProfileUseCase>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
