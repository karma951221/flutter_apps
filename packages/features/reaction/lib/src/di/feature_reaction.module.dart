// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../data/datasource/reaction_data_source.dart' as _i213;
import '../data/datasource/supabase_reaction_data_source.dart' as _i824;
import '../data/repository/reaction_repository_impl.dart' as _i747;
import '../domain/repository/reaction_repository.dart' as _i317;
import '../domain/usecase/reaction_use_case.dart' as _i314;

class FeatureReactionPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i213.ReactionDataSource>(
        () => _i824.SupabaseReactionDataSource(gh<_i454.SupabaseClient>()));
    gh.lazySingleton<_i317.ReactionRepository>(
        () => _i747.ReactionRepositoryImpl(gh<_i213.ReactionDataSource>()));
    gh.lazySingleton<_i314.ReactionUseCase>(
        () => _i314.DefaultReactionUseCase(gh<_i317.ReactionRepository>()));
  }
}
