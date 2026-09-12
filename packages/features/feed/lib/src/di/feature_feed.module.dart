// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:feature_post/feature_post.dart' as _i317;
import 'package:feature_reaction/feature_reaction.dart' as _i766;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../data/datasource/feed_data_source.dart' as _i156;
import '../data/datasource/supabase_feed_data_source.dart' as _i91;
import '../data/repository/feed_repository_impl.dart' as _i248;
import '../domain/repository/feed_repository.dart' as _i81;
import '../domain/usecase/feed_use_case.dart' as _i884;
import '../presentation/cubit/feed_cubit.dart' as _i192;

class FeatureFeedPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i156.FeedDataSource>(
        () => _i91.SupabaseFeedDataSource(gh<_i454.SupabaseClient>()));
    gh.lazySingleton<_i81.FeedRepository>(
        () => _i248.FeedRepositoryImpl(gh<_i156.FeedDataSource>()));
    gh.lazySingleton<_i884.FeedUseCase>(() => _i884.DefaultFeedUseCase(
          gh<_i81.FeedRepository>(),
          gh<_i317.PostUseCase>(),
        ));
    gh.factory<_i192.FeedCubit>(() => _i192.FeedCubit(
          gh<_i884.FeedUseCase>(),
          gh<_i766.ReactionUseCase>(),
        ));
  }
}
