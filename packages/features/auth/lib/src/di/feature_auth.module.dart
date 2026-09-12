// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:core/core.dart' as _i494;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../data/datasource/auth_data_source.dart' as _i979;
import '../data/datasource/supabase_auth_data_source.dart' as _i348;
import '../data/repository/supabase_auth_repository.dart' as _i447;
import '../domain/repository/auth_repository.dart' as _i306;
import '../domain/usecase/auth_use_case.dart' as _i959;
import '../presentation/bloc/auth_bloc.dart' as _i244;
import '../presentation/cubit/password_reset_cubit.dart' as _i849;
import '../presentation/cubit/sign_in_cubit.dart' as _i903;
import '../presentation/cubit/sign_up_cubit.dart' as _i537;

class FeatureAuthPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i979.AuthDataSource>(
        () => _i348.SupabaseAuthDataSource(gh<_i454.SupabaseClient>()));
    gh.lazySingleton<_i306.AuthRepository>(() => _i447.SupabaseAuthRepository(
          gh<_i979.AuthDataSource>(),
          gh<_i494.ImageStorage>(),
        ));
    gh.lazySingleton<_i959.AuthUseCase>(
        () => _i959.DefaultAuthUseCase(gh<_i306.AuthRepository>()));
    gh.factory<_i244.AuthBloc>(() => _i244.AuthBloc(gh<_i959.AuthUseCase>()));
    gh.factory<_i849.PasswordResetCubit>(
        () => _i849.PasswordResetCubit(gh<_i959.AuthUseCase>()));
    gh.factory<_i903.SignInCubit>(
        () => _i903.SignInCubit(gh<_i959.AuthUseCase>()));
    gh.factory<_i537.SignUpCubit>(
        () => _i537.SignUpCubit(gh<_i959.AuthUseCase>()));
  }
}
