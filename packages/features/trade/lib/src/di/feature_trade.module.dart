// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../data/datasource/supabase_trade_data_source.dart' as _i424;
import '../data/datasource/trade_data_source.dart' as _i661;
import '../data/repository/trade_repository_impl.dart' as _i243;
import '../domain/repository/trade_repository.dart' as _i365;
import '../domain/usecase/trade_use_case.dart' as _i757;
import '../presentation/cubit/trade_home_cubit.dart' as _i542;
import '../presentation/cubit/trade_session_cubit.dart' as _i437;

class FeatureTradePackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i661.TradeDataSource>(
        () => _i424.SupabaseTradeDataSource(gh<_i454.SupabaseClient>()));
    gh.lazySingleton<_i365.TradeRepository>(
        () => _i243.TradeRepositoryImpl(gh<_i661.TradeDataSource>()));
    gh.lazySingleton<_i757.TradeUseCase>(
        () => _i757.DefaultTradeUseCase(gh<_i365.TradeRepository>()));
    gh.factory<_i542.TradeHomeCubit>(
        () => _i542.TradeHomeCubit(gh<_i757.TradeUseCase>()));
    gh.factory<_i437.TradeSessionCubit>(
        () => _i437.TradeSessionCubit(gh<_i757.TradeUseCase>()));
  }
}
