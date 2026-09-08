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
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;
import 'package:uuid/uuid.dart' as _i706;

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
import '../../features/chat/data/datasource/chat_data_source.dart' as _i47;
import '../../features/chat/data/datasource/supabase_chat_data_source.dart'
    as _i574;
import '../../features/chat/data/repository/chat_repository_impl.dart' as _i88;
import '../../features/chat/domain/repository/chat_repository.dart' as _i477;
import '../../features/chat/domain/usecase/chat_use_case.dart' as _i754;
import '../../features/chat/presentation/bloc/chat_room_bloc.dart' as _i56;
import '../../features/chat/presentation/cubit/chat_explore_cubit.dart'
    as _i637;
import '../../features/chat/presentation/cubit/chat_room_list_cubit.dart'
    as _i81;
import '../../features/chat/presentation/cubit/create_room_cubit.dart' as _i808;
import '../../features/comment/data/datasource/comment_data_source.dart'
    as _i896;
import '../../features/comment/data/datasource/supabase_comment_data_source.dart'
    as _i296;
import '../../features/comment/data/repository/comment_repository_impl.dart'
    as _i742;
import '../../features/comment/domain/repository/comment_repository.dart'
    as _i813;
import '../../features/comment/domain/usecase/comment_use_case.dart' as _i1011;
import '../../features/comment/presentation/cubit/comment_cubit.dart' as _i37;
import '../../features/feed/data/datasource/feed_data_source.dart' as _i514;
import '../../features/feed/data/datasource/supabase_feed_data_source.dart'
    as _i402;
import '../../features/feed/data/repository/feed_repository_impl.dart' as _i749;
import '../../features/feed/domain/repository/feed_repository.dart' as _i898;
import '../../features/feed/domain/usecase/feed_use_case.dart' as _i1009;
import '../../features/feed/presentation/cubit/feed_cubit.dart' as _i58;
import '../../features/follow/data/datasource/follow_data_source.dart' as _i40;
import '../../features/follow/data/datasource/supabase_follow_data_source.dart'
    as _i161;
import '../../features/follow/data/repository/follow_repository_impl.dart'
    as _i257;
import '../../features/follow/domain/repository/follow_repository.dart'
    as _i903;
import '../../features/follow/domain/usecase/follow_use_case.dart' as _i223;
import '../../features/follow/presentation/cubit/follow_action_cubit.dart'
    as _i843;
import '../../features/follow/presentation/cubit/follow_list_cubit.dart'
    as _i281;
import '../../features/post/data/datasource/post_data_source.dart' as _i487;
import '../../features/post/data/datasource/supabase_post_data_source.dart'
    as _i215;
import '../../features/post/data/repository/post_repository_impl.dart' as _i238;
import '../../features/post/domain/repository/post_repository.dart' as _i735;
import '../../features/post/domain/usecase/post_use_case.dart' as _i944;
import '../../features/post/presentation/cubit/post_cubit.dart' as _i1054;
import '../../features/preferences/data/datasource/language_data_source.dart'
    as _i699;
import '../../features/preferences/data/datasource/preferences_language_data_source.dart'
    as _i279;
import '../../features/preferences/data/datasource/preferences_theme_data_source.dart'
    as _i184;
import '../../features/preferences/data/datasource/theme_data_source.dart'
    as _i315;
import '../../features/preferences/data/repository/language_repository_impl.dart'
    as _i738;
import '../../features/preferences/data/repository/theme_repository_impl.dart'
    as _i514;
import '../../features/preferences/domain/repository/language_repository.dart'
    as _i353;
import '../../features/preferences/domain/repository/theme_repository.dart'
    as _i979;
import '../../features/preferences/domain/usecase/preferences_use_case.dart'
    as _i414;
import '../../features/preferences/presentation/cubit/language_cubit.dart'
    as _i214;
import '../../features/preferences/presentation/cubit/theme_cubit.dart' as _i81;
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
import '../../features/reaction/data/datasource/reaction_data_source.dart'
    as _i281;
import '../../features/reaction/data/datasource/supabase_reaction_data_source.dart'
    as _i549;
import '../../features/reaction/data/repository/reaction_repository_impl.dart'
    as _i1063;
import '../../features/reaction/domain/repository/reaction_repository.dart'
    as _i831;
import '../../features/reaction/domain/usecase/reaction_use_case.dart' as _i650;
import '../../features/safety/data/datasource/block_data_source.dart' as _i452;
import '../../features/safety/data/datasource/report_data_source.dart' as _i249;
import '../../features/safety/data/datasource/supabase_block_data_source.dart'
    as _i880;
import '../../features/safety/data/datasource/supabase_report_data_source.dart'
    as _i294;
import '../../features/safety/data/repository/block_repository_impl.dart'
    as _i659;
import '../../features/safety/data/repository/report_repository_impl.dart'
    as _i1002;
import '../../features/safety/domain/repository/block_repository.dart' as _i892;
import '../../features/safety/domain/repository/report_repository.dart' as _i29;
import '../../features/safety/domain/usecase/safety_use_case.dart' as _i762;
import '../../features/safety/presentation/cubit/block_action_cubit.dart'
    as _i26;
import '../../features/safety/presentation/cubit/blocked_users_cubit.dart'
    as _i50;
import '../../features/safety/presentation/cubit/report_cubit.dart' as _i347;
import '../../features/settings/data/datasource/account_data_source.dart'
    as _i1004;
import '../../features/settings/data/datasource/supabase_account_data_source.dart'
    as _i589;
import '../../features/settings/data/repository/account_repository_impl.dart'
    as _i820;
import '../../features/settings/domain/repository/account_repository.dart'
    as _i13;
import '../../features/settings/domain/usecase/account_use_case.dart' as _i727;
import '../../features/settings/presentation/cubit/change_password_cubit.dart'
    as _i903;
import '../../features/settings/presentation/cubit/delete_account_cubit.dart'
    as _i77;
import '../../features/trade/data/datasource/supabase_trade_data_source.dart'
    as _i386;
import '../../features/trade/data/datasource/trade_data_source.dart' as _i740;
import '../../features/trade/data/repository/trade_repository_impl.dart'
    as _i632;
import '../../features/trade/domain/repository/trade_repository.dart' as _i776;
import '../../features/trade/domain/usecase/trade_use_case.dart' as _i903;
import '../../features/trade/presentation/cubit/trade_home_cubit.dart' as _i364;
import '../../features/trade/presentation/cubit/trade_session_cubit.dart'
    as _i371;
import '../id/id_generator.dart' as _i1000;
import '../media/image_picker_service.dart' as _i350;
import '../media/image_storage.dart' as _i1040;
import '../media/supabase_image_storage.dart' as _i571;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i454.SupabaseClient>(() => registerModule.supabaseClient);
    gh.lazySingleton<_i706.Uuid>(() => registerModule.uuid);
    gh.lazySingleton<_i350.ImagePickerService>(
      () => _i350.ImagePickerService(),
    );
    gh.lazySingleton<_i315.ThemeDataSource>(
      () => _i184.PreferencesThemeDataSource(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i979.ThemeRepository>(
      () => _i514.ThemeRepositoryImpl(gh<_i315.ThemeDataSource>()),
    );
    gh.lazySingleton<_i699.LanguageDataSource>(
      () => _i279.PreferencesLanguageDataSource(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i1000.IdGenerator>(
      () => _i1000.IdGenerator(gh<_i706.Uuid>()),
    );
    gh.lazySingleton<_i353.LanguageRepository>(
      () => _i738.LanguageRepositoryImpl(gh<_i699.LanguageDataSource>()),
    );
    gh.lazySingleton<_i249.ReportDataSource>(
      () => _i294.SupabaseReportDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i514.FeedDataSource>(
      () => _i402.SupabaseFeedDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i896.CommentDataSource>(
      () => _i296.SupabaseCommentDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i1040.ImageStorage>(
      () => _i571.SupabaseImageStorage(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i281.ReactionDataSource>(
      () => _i549.SupabaseReactionDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i740.TradeDataSource>(
      () => _i386.SupabaseTradeDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i47.ChatDataSource>(
      () => _i574.SupabaseChatDataSource(
        gh<_i454.SupabaseClient>(),
        gh<_i1040.ImageStorage>(),
      ),
    );
    gh.lazySingleton<_i414.PreferencesUseCase>(
      () => _i414.DefaultPreferencesUseCase(
        gh<_i979.ThemeRepository>(),
        gh<_i353.LanguageRepository>(),
      ),
    );
    gh.lazySingleton<_i452.BlockDataSource>(
      () => _i880.SupabaseBlockDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.factory<_i214.LanguageCubit>(
      () => _i214.LanguageCubit(gh<_i414.PreferencesUseCase>()),
    );
    gh.factory<_i81.ThemeCubit>(
      () => _i81.ThemeCubit(gh<_i414.PreferencesUseCase>()),
    );
    gh.lazySingleton<_i813.CommentRepository>(
      () => _i742.CommentRepositoryImpl(gh<_i896.CommentDataSource>()),
    );
    gh.lazySingleton<_i477.ChatRepository>(
      () => _i88.ChatRepositoryImpl(gh<_i47.ChatDataSource>()),
    );
    gh.lazySingleton<_i692.AuthDataSource>(
      () => _i87.SupabaseAuthDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i40.FollowDataSource>(
      () => _i161.SupabaseFollowDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i1004.AccountDataSource>(
      () => _i589.SupabaseAccountDataSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i776.TradeRepository>(
      () => _i632.TradeRepositoryImpl(gh<_i740.TradeDataSource>()),
    );
    gh.lazySingleton<_i903.TradeUseCase>(
      () => _i903.DefaultTradeUseCase(gh<_i776.TradeRepository>()),
    );
    gh.lazySingleton<_i892.BlockRepository>(
      () => _i659.BlockRepositoryImpl(gh<_i452.BlockDataSource>()),
    );
    gh.lazySingleton<_i487.PostDataSource>(
      () => _i215.SupabasePostDataSource(
        gh<_i454.SupabaseClient>(),
        gh<_i1000.IdGenerator>(),
        gh<_i1040.ImageStorage>(),
      ),
    );
    gh.lazySingleton<_i1011.CommentUseCase>(
      () => _i1011.DefaultCommentUseCase(gh<_i813.CommentRepository>()),
    );
    gh.lazySingleton<_i29.ReportRepository>(
      () => _i1002.ReportRepositoryImpl(gh<_i249.ReportDataSource>()),
    );
    gh.lazySingleton<_i898.FeedRepository>(
      () => _i749.FeedRepositoryImpl(gh<_i514.FeedDataSource>()),
    );
    gh.lazySingleton<_i754.ChatUseCase>(
      () => _i754.DefaultChatUseCase(
        gh<_i477.ChatRepository>(),
        gh<_i1000.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i13.AccountRepository>(
      () => _i820.AccountRepositoryImpl(gh<_i1004.AccountDataSource>()),
    );
    gh.lazySingleton<_i903.FollowRepository>(
      () => _i257.FollowRepositoryImpl(gh<_i40.FollowDataSource>()),
    );
    gh.lazySingleton<_i1009.FeedUseCase>(
      () => _i1009.DefaultFeedUseCase(gh<_i898.FeedRepository>()),
    );
    gh.lazySingleton<_i986.ProfileDataSource>(
      () => _i787.SupabaseProfileDataSource(
        gh<_i454.SupabaseClient>(),
        gh<_i1040.ImageStorage>(),
      ),
    );
    gh.lazySingleton<_i364.ProfileRepository>(
      () => _i309.ProfileRepositoryImpl(gh<_i986.ProfileDataSource>()),
    );
    gh.lazySingleton<_i223.FollowUseCase>(
      () => _i223.DefaultFollowUseCase(gh<_i903.FollowRepository>()),
    );
    gh.lazySingleton<_i831.ReactionRepository>(
      () => _i1063.ReactionRepositoryImpl(gh<_i281.ReactionDataSource>()),
    );
    gh.lazySingleton<_i961.AuthRepository>(
      () => _i971.SupabaseAuthRepository(
        gh<_i692.AuthDataSource>(),
        gh<_i1040.ImageStorage>(),
      ),
    );
    gh.factory<_i56.ChatRoomBloc>(
      () => _i56.ChatRoomBloc(gh<_i754.ChatUseCase>()),
    );
    gh.factory<_i637.ChatExploreCubit>(
      () => _i637.ChatExploreCubit(gh<_i754.ChatUseCase>()),
    );
    gh.factory<_i81.ChatRoomListCubit>(
      () => _i81.ChatRoomListCubit(gh<_i754.ChatUseCase>()),
    );
    gh.factory<_i808.CreateRoomCubit>(
      () => _i808.CreateRoomCubit(gh<_i754.ChatUseCase>()),
    );
    gh.lazySingleton<_i735.PostRepository>(
      () => _i238.PostRepositoryImpl(gh<_i487.PostDataSource>()),
    );
    gh.lazySingleton<_i944.PostUseCase>(
      () => _i944.DefaultPostUseCase(gh<_i735.PostRepository>()),
    );
    gh.factory<_i364.TradeHomeCubit>(
      () => _i364.TradeHomeCubit(gh<_i903.TradeUseCase>()),
    );
    gh.factory<_i371.TradeSessionCubit>(
      () => _i371.TradeSessionCubit(gh<_i903.TradeUseCase>()),
    );
    gh.lazySingleton<_i762.SafetyUseCase>(
      () => _i762.DefaultSafetyUseCase(
        gh<_i29.ReportRepository>(),
        gh<_i892.BlockRepository>(),
      ),
    );
    gh.lazySingleton<_i176.AuthUseCase>(
      () => _i176.DefaultAuthUseCase(gh<_i961.AuthRepository>()),
    );
    gh.lazySingleton<_i727.AccountUseCase>(
      () => _i727.DefaultAccountUseCase(gh<_i13.AccountRepository>()),
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
    gh.factory<_i903.ChangePasswordCubit>(
      () => _i903.ChangePasswordCubit(gh<_i176.AuthUseCase>()),
    );
    gh.factory<_i77.DeleteAccountCubit>(
      () => _i77.DeleteAccountCubit(gh<_i176.AuthUseCase>()),
    );
    gh.lazySingleton<_i408.ProfileUseCase>(
      () => _i408.DefaultProfileUseCase(gh<_i364.ProfileRepository>()),
    );
    gh.factory<_i1054.PostCubit>(
      () => _i1054.PostCubit(gh<_i944.PostUseCase>()),
    );
    gh.factory<_i36.ProfileCubit>(
      () => _i36.ProfileCubit(gh<_i408.ProfileUseCase>()),
    );
    gh.lazySingleton<_i650.ReactionUseCase>(
      () => _i650.DefaultReactionUseCase(gh<_i831.ReactionRepository>()),
    );
    gh.factory<_i843.FollowActionCubit>(
      () => _i843.FollowActionCubit(gh<_i223.FollowUseCase>()),
    );
    gh.factory<_i281.FollowListCubit>(
      () => _i281.FollowListCubit(gh<_i223.FollowUseCase>()),
    );
    gh.factory<_i26.BlockActionCubit>(
      () => _i26.BlockActionCubit(gh<_i762.SafetyUseCase>()),
    );
    gh.factory<_i50.BlockedUsersCubit>(
      () => _i50.BlockedUsersCubit(gh<_i762.SafetyUseCase>()),
    );
    gh.factory<_i347.ReportCubit>(
      () => _i347.ReportCubit(gh<_i762.SafetyUseCase>()),
    );
    gh.factory<_i58.FeedCubit>(
      () =>
          _i58.FeedCubit(gh<_i1009.FeedUseCase>(), gh<_i650.ReactionUseCase>()),
    );
    gh.factory<_i37.CommentCubit>(
      () => _i37.CommentCubit(
        gh<_i1011.CommentUseCase>(),
        gh<_i650.ReactionUseCase>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
