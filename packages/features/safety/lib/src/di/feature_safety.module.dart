// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../data/datasource/block_data_source.dart' as _i733;
import '../data/datasource/report_data_source.dart' as _i327;
import '../data/datasource/supabase_block_data_source.dart' as _i601;
import '../data/datasource/supabase_report_data_source.dart' as _i910;
import '../data/repository/block_repository_impl.dart' as _i721;
import '../data/repository/report_repository_impl.dart' as _i751;
import '../domain/repository/block_repository.dart' as _i563;
import '../domain/repository/report_repository.dart' as _i739;
import '../domain/usecase/safety_use_case.dart' as _i169;
import '../presentation/cubit/block_action_cubit.dart' as _i950;
import '../presentation/cubit/blocked_users_cubit.dart' as _i274;
import '../presentation/cubit/report_cubit.dart' as _i581;

class FeatureSafetyPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i327.ReportDataSource>(
        () => _i910.SupabaseReportDataSource(gh<_i454.SupabaseClient>()));
    gh.lazySingleton<_i733.BlockDataSource>(
        () => _i601.SupabaseBlockDataSource(gh<_i454.SupabaseClient>()));
    gh.lazySingleton<_i739.ReportRepository>(
        () => _i751.ReportRepositoryImpl(gh<_i327.ReportDataSource>()));
    gh.lazySingleton<_i563.BlockRepository>(
        () => _i721.BlockRepositoryImpl(gh<_i733.BlockDataSource>()));
    gh.lazySingleton<_i169.SafetyUseCase>(() => _i169.DefaultSafetyUseCase(
          gh<_i739.ReportRepository>(),
          gh<_i563.BlockRepository>(),
        ));
    gh.factory<_i950.BlockActionCubit>(
        () => _i950.BlockActionCubit(gh<_i169.SafetyUseCase>()));
    gh.factory<_i274.BlockedUsersCubit>(
        () => _i274.BlockedUsersCubit(gh<_i169.SafetyUseCase>()));
    gh.factory<_i581.ReportCubit>(
        () => _i581.ReportCubit(gh<_i169.SafetyUseCase>()));
  }
}
