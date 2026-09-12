// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:feature_auth/feature_auth.dart' as _i277;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../data/datasource/account_data_source.dart' as _i252;
import '../data/datasource/supabase_account_data_source.dart' as _i1034;
import '../data/repository/account_repository_impl.dart' as _i317;
import '../domain/repository/account_repository.dart' as _i170;
import '../domain/usecase/account_use_case.dart' as _i603;
import '../presentation/cubit/change_password_cubit.dart' as _i877;
import '../presentation/cubit/delete_account_cubit.dart' as _i325;

class FeatureSettingsPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.factory<_i877.ChangePasswordCubit>(
        () => _i877.ChangePasswordCubit(gh<_i277.AuthUseCase>()));
    gh.factory<_i325.DeleteAccountCubit>(
        () => _i325.DeleteAccountCubit(gh<_i277.AuthUseCase>()));
    gh.lazySingleton<_i252.AccountDataSource>(
        () => _i1034.SupabaseAccountDataSource(gh<_i454.SupabaseClient>()));
    gh.lazySingleton<_i170.AccountRepository>(
        () => _i317.AccountRepositoryImpl(gh<_i252.AccountDataSource>()));
    gh.lazySingleton<_i603.AccountUseCase>(
        () => _i603.DefaultAccountUseCase(gh<_i170.AccountRepository>()));
  }
}
