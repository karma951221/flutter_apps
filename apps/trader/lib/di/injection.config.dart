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
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../features/chat/data/datasource/chat_data_source.dart' as _i694;
import '../features/chat/data/datasource/supabase_chat_data_source.dart'
    as _i971;
import '../features/chat/data/repository/chat_repository_impl.dart' as _i176;
import '../features/chat/domain/repository/chat_repository.dart' as _i206;
import '../features/chat/domain/usecase/chat_use_case.dart' as _i609;
import '../features/chat/presentation/bloc/chat_room_bloc.dart' as _i611;
import '../features/chat/presentation/cubit/chat_explore_cubit.dart' as _i405;
import '../features/chat/presentation/cubit/chat_room_list_cubit.dart' as _i599;
import '../features/chat/presentation/cubit/create_room_cubit.dart' as _i752;
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
import '../features/follow/data/datasource/follow_data_source.dart' as _i682;
import '../features/follow/data/datasource/supabase_follow_data_source.dart'
    as _i203;
import '../features/follow/data/repository/follow_repository_impl.dart'
    as _i709;
import '../features/follow/domain/repository/follow_repository.dart' as _i506;
import '../features/follow/domain/usecase/follow_use_case.dart' as _i90;
import '../features/follow/presentation/cubit/follow_action_cubit.dart' as _i89;
import '../features/follow/presentation/cubit/follow_list_cubit.dart' as _i818;
import '../features/post/data/datasource/post_data_source.dart' as _i349;
import '../features/post/data/datasource/supabase_post_data_source.dart'
    as _i414;
import '../features/post/data/repository/post_repository_impl.dart' as _i366;
import '../features/post/domain/repository/post_repository.dart' as _i615;
import '../features/post/domain/usecase/post_use_case.dart' as _i564;
import '../features/post/presentation/cubit/post_cubit.dart' as _i182;
import '../features/preferences/data/datasource/language_data_source.dart'
    as _i683;
import '../features/preferences/data/datasource/preferences_language_data_source.dart'
    as _i783;
import '../features/preferences/data/datasource/preferences_theme_data_source.dart'
    as _i158;
import '../features/preferences/data/datasource/theme_data_source.dart'
    as _i376;
import '../features/preferences/data/repository/language_repository_impl.dart'
    as _i134;
import '../features/preferences/data/repository/theme_repository_impl.dart'
    as _i767;
import '../features/preferences/domain/repository/language_repository.dart'
    as _i857;
import '../features/preferences/domain/repository/theme_repository.dart'
    as _i659;
import '../features/preferences/domain/usecase/preferences_use_case.dart'
    as _i962;
import '../features/preferences/presentation/cubit/language_cubit.dart'
    as _i639;
import '../features/preferences/presentation/cubit/theme_cubit.dart' as _i478;
import '../features/profile/data/datasource/profile_data_source.dart' as _i654;
import '../features/profile/data/datasource/supabase_profile_data_source.dart'
    as _i211;
import '../features/profile/data/repository/profile_repository_impl.dart'
    as _i259;
import '../features/profile/domain/repository/profile_repository.dart' as _i928;
import '../features/profile/domain/usecase/profile_use_case.dart' as _i640;
import '../features/profile/presentation/cubit/profile_cubit.dart' as _i300;
import '../features/reaction/data/datasource/reaction_data_source.dart'
    as _i128;
import '../features/reaction/data/datasource/supabase_reaction_data_source.dart'
    as _i480;
import '../features/reaction/data/repository/reaction_repository_impl.dart'
    as _i1043;
import '../features/reaction/domain/repository/reaction_repository.dart'
    as _i996;
import '../features/reaction/domain/usecase/reaction_use_case.dart' as _i387;
import '../features/safety/data/datasource/block_data_source.dart' as _i920;
import '../features/safety/data/datasource/report_data_source.dart' as _i972;
import '../features/safety/data/datasource/supabase_block_data_source.dart'
    as _i247;
import '../features/safety/data/datasource/supabase_report_data_source.dart'
    as _i1067;
import '../features/safety/data/repository/block_repository_impl.dart' as _i349;
import '../features/safety/data/repository/report_repository_impl.dart'
    as _i617;
import '../features/safety/domain/repository/block_repository.dart' as _i609;
import '../features/safety/domain/repository/report_repository.dart' as _i179;
import '../features/safety/domain/usecase/safety_use_case.dart' as _i262;
import '../features/safety/presentation/cubit/block_action_cubit.dart' as _i32;
import '../features/safety/presentation/cubit/blocked_users_cubit.dart'
    as _i177;
import '../features/safety/presentation/cubit/report_cubit.dart' as _i925;
import '../features/settings/data/datasource/account_data_source.dart' as _i249;
import '../features/settings/data/datasource/supabase_account_data_source.dart'
    as _i139;
import '../features/settings/data/repository/account_repository_impl.dart'
    as _i934;
import '../features/settings/domain/repository/account_repository.dart'
    as _i186;
import '../features/settings/domain/usecase/account_use_case.dart' as _i141;
import '../features/settings/presentation/cubit/change_password_cubit.dart'
    as _i459;
import '../features/settings/presentation/cubit/delete_account_cubit.dart'
    as _i966;
import '../features/trade/data/datasource/supabase_trade_data_source.dart'
    as _i1052;
import '../features/trade/data/datasource/trade_data_source.dart' as _i345;
import '../features/trade/data/repository/trade_repository_impl.dart' as _i488;
import '../features/trade/domain/repository/trade_repository.dart' as _i289;
import '../features/trade/domain/usecase/trade_use_case.dart' as _i835;
import '../features/trade/presentation/cubit/trade_home_cubit.dart' as _i202;
import '../features/trade/presentation/cubit/trade_session_cubit.dart' as _i135;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    await _i494.CorePackageModule().init(gh);
    await _i277.FeatureAuthPackageModule().init(gh);
    gh.lazySingleton<_i376.ThemeDataSource>(
      () => _i158.PreferencesThemeDataSource(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i659.ThemeRepository>(
      () => _i767.ThemeRepositoryImpl(gh<_i376.ThemeDataSource>()),
    );
    gh.factory<_i459.ChangePasswordCubit>(
      () => _i459.ChangePasswordCubit(gh<_i277.AuthUseCase>()),
    );
    gh.factory<_i966.DeleteAccountCubit>(
      () => _i966.DeleteAccountCubit(gh<_i277.AuthUseCase>()),
    );
    gh.lazySingleton<_i683.LanguageDataSource>(
      () => _i783.PreferencesLanguageDataSource(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i857.LanguageRepository>(
      () => _i134.LanguageRepositoryImpl(gh<_i683.LanguageDataSource>()),
    );
    gh.lazySingleton<_i972.ReportDataSource>(
      () => _i1067.SupabaseReportDataSource(gh<_i454.SupabaseClient>()),
    );
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
    gh.lazySingleton<_i349.PostDataSource>(
      () => _i414.SupabasePostDataSource(
        gh<_i454.SupabaseClient>(),
        gh<_i494.IdGenerator>(),
        gh<_i494.ImageStorage>(),
      ),
    );
    gh.lazySingleton<_i128.ReactionDataSource>(
      () => _i480.SupabaseReactionDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i345.TradeDataSource>(
      () => _i1052.SupabaseTradeDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i694.ChatDataSource>(
      () => _i971.SupabaseChatDataSource(
        gh<_i454.SupabaseClient>(),
        gh<_i494.ImageStorage>(),
      ),
    );
    gh.lazySingleton<_i962.PreferencesUseCase>(
      () => _i962.DefaultPreferencesUseCase(
        gh<_i659.ThemeRepository>(),
        gh<_i857.LanguageRepository>(),
      ),
    );
    gh.lazySingleton<_i920.BlockDataSource>(
      () => _i247.SupabaseBlockDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.factory<_i639.LanguageCubit>(
      () => _i639.LanguageCubit(gh<_i962.PreferencesUseCase>()),
    );
    gh.factory<_i478.ThemeCubit>(
      () => _i478.ThemeCubit(gh<_i962.PreferencesUseCase>()),
    );
    gh.lazySingleton<_i237.CommentRepository>(
      () => _i740.CommentRepositoryImpl(gh<_i920.CommentDataSource>()),
    );
    gh.lazySingleton<_i615.PostRepository>(
      () => _i366.PostRepositoryImpl(gh<_i349.PostDataSource>()),
    );
    gh.lazySingleton<_i206.ChatRepository>(
      () => _i176.ChatRepositoryImpl(gh<_i694.ChatDataSource>()),
    );
    gh.lazySingleton<_i682.FollowDataSource>(
      () => _i203.SupabaseFollowDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i249.AccountDataSource>(
      () => _i139.SupabaseAccountDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i564.PostUseCase>(
      () => _i564.DefaultPostUseCase(gh<_i615.PostRepository>()),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i289.TradeRepository>(
      () => _i488.TradeRepositoryImpl(gh<_i345.TradeDataSource>()),
    );
    gh.lazySingleton<_i835.TradeUseCase>(
      () => _i835.DefaultTradeUseCase(gh<_i289.TradeRepository>()),
    );
    gh.lazySingleton<_i609.BlockRepository>(
      () => _i349.BlockRepositoryImpl(gh<_i920.BlockDataSource>()),
    );
    gh.lazySingleton<_i13.CommentUseCase>(
      () => _i13.DefaultCommentUseCase(gh<_i237.CommentRepository>()),
    );
    gh.lazySingleton<_i179.ReportRepository>(
      () => _i617.ReportRepositoryImpl(gh<_i972.ReportDataSource>()),
    );
    gh.lazySingleton<_i522.FeedRepository>(
      () => _i264.FeedRepositoryImpl(gh<_i247.FeedDataSource>()),
    );
    gh.lazySingleton<_i640.ProfileUseCase>(
      () => _i640.DefaultProfileUseCase(gh<_i928.ProfileRepository>()),
    );
    gh.factory<_i182.PostCubit>(() => _i182.PostCubit(gh<_i564.PostUseCase>()));
    gh.factory<_i300.ProfileCubit>(
      () => _i300.ProfileCubit(gh<_i640.ProfileUseCase>()),
    );
    gh.lazySingleton<_i556.FeedUseCase>(
      () => _i556.DefaultFeedUseCase(
        gh<_i522.FeedRepository>(),
        gh<_i564.PostUseCase>(),
      ),
    );
    gh.lazySingleton<_i186.AccountRepository>(
      () => _i934.AccountRepositoryImpl(gh<_i249.AccountDataSource>()),
    );
    gh.lazySingleton<_i609.ChatUseCase>(
      () => _i609.DefaultChatUseCase(
        gh<_i206.ChatRepository>(),
        gh<_i494.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i506.FollowRepository>(
      () => _i709.FollowRepositoryImpl(gh<_i682.FollowDataSource>()),
    );
    gh.lazySingleton<_i90.FollowUseCase>(
      () => _i90.DefaultFollowUseCase(gh<_i506.FollowRepository>()),
    );
    gh.lazySingleton<_i996.ReactionRepository>(
      () => _i1043.ReactionRepositoryImpl(gh<_i128.ReactionDataSource>()),
    );
    gh.factory<_i611.ChatRoomBloc>(
      () => _i611.ChatRoomBloc(gh<_i609.ChatUseCase>()),
    );
    gh.factory<_i405.ChatExploreCubit>(
      () => _i405.ChatExploreCubit(gh<_i609.ChatUseCase>()),
    );
    gh.factory<_i599.ChatRoomListCubit>(
      () => _i599.ChatRoomListCubit(gh<_i609.ChatUseCase>()),
    );
    gh.factory<_i752.CreateRoomCubit>(
      () => _i752.CreateRoomCubit(gh<_i609.ChatUseCase>()),
    );
    gh.factory<_i202.TradeHomeCubit>(
      () => _i202.TradeHomeCubit(gh<_i835.TradeUseCase>()),
    );
    gh.factory<_i135.TradeSessionCubit>(
      () => _i135.TradeSessionCubit(gh<_i835.TradeUseCase>()),
    );
    gh.lazySingleton<_i262.SafetyUseCase>(
      () => _i262.DefaultSafetyUseCase(
        gh<_i179.ReportRepository>(),
        gh<_i609.BlockRepository>(),
      ),
    );
    gh.lazySingleton<_i141.AccountUseCase>(
      () => _i141.DefaultAccountUseCase(gh<_i186.AccountRepository>()),
    );
    gh.lazySingleton<_i387.ReactionUseCase>(
      () => _i387.DefaultReactionUseCase(gh<_i996.ReactionRepository>()),
    );
    gh.factory<_i89.FollowActionCubit>(
      () => _i89.FollowActionCubit(gh<_i90.FollowUseCase>()),
    );
    gh.factory<_i818.FollowListCubit>(
      () => _i818.FollowListCubit(gh<_i90.FollowUseCase>()),
    );
    gh.factory<_i32.BlockActionCubit>(
      () => _i32.BlockActionCubit(gh<_i262.SafetyUseCase>()),
    );
    gh.factory<_i177.BlockedUsersCubit>(
      () => _i177.BlockedUsersCubit(gh<_i262.SafetyUseCase>()),
    );
    gh.factory<_i925.ReportCubit>(
      () => _i925.ReportCubit(gh<_i262.SafetyUseCase>()),
    );
    gh.factory<_i482.FeedCubit>(
      () =>
          _i482.FeedCubit(gh<_i556.FeedUseCase>(), gh<_i387.ReactionUseCase>()),
    );
    gh.factory<_i630.CommentCubit>(
      () => _i630.CommentCubit(
        gh<_i13.CommentUseCase>(),
        gh<_i387.ReactionUseCase>(),
      ),
    );
    return this;
  }
}
