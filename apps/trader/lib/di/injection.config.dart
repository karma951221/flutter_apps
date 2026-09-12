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
import 'package:feature_comment/feature_comment.dart' as _i726;
import 'package:feature_feed/feature_feed.dart' as _i1049;
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
    await _i726.FeatureCommentPackageModule().init(gh);
    await _i1049.FeatureFeedPackageModule().init(gh);
    gh.lazySingleton<_i654.ProfileDataSource>(
      () => _i211.SupabaseProfileDataSource(
        gh<_i454.SupabaseClient>(),
        gh<_i494.ImageStorage>(),
      ),
    );
    gh.lazySingleton<_i928.ProfileRepository>(
      () => _i259.ProfileRepositoryImpl(gh<_i654.ProfileDataSource>()),
    );
    gh.lazySingleton<_i640.ProfileUseCase>(
      () => _i640.DefaultProfileUseCase(gh<_i928.ProfileRepository>()),
    );
    gh.factory<_i300.ProfileCubit>(
      () => _i300.ProfileCubit(gh<_i640.ProfileUseCase>()),
    );
    return this;
  }
}
