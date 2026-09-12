// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:core/core.dart' as _i494;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../data/datasource/chat_data_source.dart' as _i758;
import '../data/datasource/supabase_chat_data_source.dart' as _i782;
import '../data/repository/chat_repository_impl.dart' as _i608;
import '../domain/repository/chat_repository.dart' as _i146;
import '../domain/usecase/chat_use_case.dart' as _i254;
import '../presentation/bloc/chat_room_bloc.dart' as _i710;
import '../presentation/cubit/chat_explore_cubit.dart' as _i47;
import '../presentation/cubit/chat_room_list_cubit.dart' as _i789;
import '../presentation/cubit/create_room_cubit.dart' as _i394;

class FeatureChatPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i758.ChatDataSource>(() => _i782.SupabaseChatDataSource(
          gh<_i454.SupabaseClient>(),
          gh<_i494.ImageStorage>(),
        ));
    gh.lazySingleton<_i146.ChatRepository>(
        () => _i608.ChatRepositoryImpl(gh<_i758.ChatDataSource>()));
    gh.lazySingleton<_i254.ChatUseCase>(() => _i254.DefaultChatUseCase(
          gh<_i146.ChatRepository>(),
          gh<_i494.IdGenerator>(),
        ));
    gh.factory<_i710.ChatRoomBloc>(
        () => _i710.ChatRoomBloc(gh<_i254.ChatUseCase>()));
    gh.factory<_i47.ChatExploreCubit>(
        () => _i47.ChatExploreCubit(gh<_i254.ChatUseCase>()));
    gh.factory<_i789.ChatRoomListCubit>(
        () => _i789.ChatRoomListCubit(gh<_i254.ChatUseCase>()));
    gh.factory<_i394.CreateRoomCubit>(
        () => _i394.CreateRoomCubit(gh<_i254.ChatUseCase>()));
  }
}
