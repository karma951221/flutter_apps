// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:core/core.dart' as _i494;
import 'package:feature_auth/feature_auth.dart' as _i277;
import 'package:feature_chat/feature_chat.dart' as _i421;
import 'package:feature_follow/feature_follow.dart' as _i324;
import 'package:feature_post/feature_post.dart' as _i317;
import 'package:feature_preferences/feature_preferences.dart' as _i769;
import 'package:feature_reaction/feature_reaction.dart' as _i766;
import 'package:feature_safety/feature_safety.dart' as _i789;
import 'package:feature_settings/feature_settings.dart' as _i427;
import 'package:feature_trade/feature_trade.dart' as _i849;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../features/comment/data/datasource/comment_data_source.dart' as _i920;
import '../features/comment/data/datasource/supabase_comment_data_source.dart'
    as _i979;
import '../features/comment/data/repository/comment_repository_impl.dart'
    as _i740;
import '../features/comment/domain/repository/comment_repository.dart' as _i237;
import '../features/comment/domain/usecase/comment_use_case.dart' as _i13;
import '../features/comment/presentation/cubit/comment_cubit.dart' as _i630;
import '../features/feed/data/datasource/feed_data_source.dart' as _i247;
import '../features/feed/data/datasource/supabase_feed_data_source.dart'
    as _i52;
import '../features/feed/data/repository/feed_repository_impl.dart' as _i264;
import '../features/feed/domain/repository/feed_repository.dart' as _i522;
import '../features/feed/domain/usecase/feed_use_case.dart' as _i556;
import '../features/feed/presentation/cubit/feed_cubit.dart' as _i482;
import '../features/profile/data/datasource/profile_data_source.dart' as _i654;
import '../features/profile/data/datasource/supabase_profile_data_source.dart'
    as _i211;
import '../features/profile/data/repository/profile_repository_impl.dart'
    as _i259;
import '../features/profile/domain/repository/profile_repository.dart' as _i928;
import '../features/profile/domain/usecase/profile_use_case.dart' as _i640;
import '../features/profile/presentation/cubit/profile_cubit.dart' as _i300;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    await _i494.CorePackageModule().init(gh);
    await _i277.FeatureAuthPackageModule().init(gh);
    await _i789.FeatureSafetyPackageModule().init(gh);
    await _i766.FeatureReactionPackageModule().init(gh);
    await _i324.FeatureFollowPackageModule().init(gh);
    await _i769.FeaturePreferencesPackageModule().init(gh);
    await _i849.FeatureTradePackageModule().init(gh);
    await _i427.FeatureSettingsPackageModule().init(gh);
    await _i421.FeatureChatPackageModule().init(gh);
    await _i317.FeaturePostPackageModule().init(gh);
    gh.lazySingleton<_i247.FeedDataSource>(
      () => _i52.SupabaseFeedDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i920.CommentDataSource>(
      () => _i979.SupabaseCommentDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i654.ProfileDataSource>(
      () => _i211.SupabaseProfileDataSource(
        gh<_i454.SupabaseClient>(),
        gh<_i494.ImageStorage>(),
      ),
    );
    gh.lazySingleton<_i928.ProfileRepository>(
      () => _i259.ProfileRepositoryImpl(gh<_i654.ProfileDataSource>()),
    );
    gh.lazySingleton<_i237.CommentRepository>(
      () => _i740.CommentRepositoryImpl(gh<_i920.CommentDataSource>()),
    );
    gh.lazySingleton<_i13.CommentUseCase>(
      () => _i13.DefaultCommentUseCase(gh<_i237.CommentRepository>()),
    );
    gh.lazySingleton<_i522.FeedRepository>(
      () => _i264.FeedRepositoryImpl(gh<_i247.FeedDataSource>()),
    );
    gh.lazySingleton<_i640.ProfileUseCase>(
      () => _i640.DefaultProfileUseCase(gh<_i928.ProfileRepository>()),
    );
    gh.factory<_i300.ProfileCubit>(
      () => _i300.ProfileCubit(gh<_i640.ProfileUseCase>()),
    );
    gh.factory<_i630.CommentCubit>(
      () => _i630.CommentCubit(
        gh<_i13.CommentUseCase>(),
        gh<_i766.ReactionUseCase>(),
      ),
    );
    gh.lazySingleton<_i556.FeedUseCase>(
      () => _i556.DefaultFeedUseCase(
        gh<_i522.FeedRepository>(),
        gh<_i317.PostUseCase>(),
      ),
    );
    gh.factory<_i482.FeedCubit>(
      () =>
          _i482.FeedCubit(gh<_i556.FeedUseCase>(), gh<_i766.ReactionUseCase>()),
    );
    return this;
  }
}
