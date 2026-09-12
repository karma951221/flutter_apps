// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:feature_reaction/feature_reaction.dart' as _i766;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../data/datasource/comment_data_source.dart' as _i201;
import '../data/datasource/supabase_comment_data_source.dart' as _i441;
import '../data/repository/comment_repository_impl.dart' as _i544;
import '../domain/repository/comment_repository.dart' as _i999;
import '../domain/usecase/comment_use_case.dart' as _i1010;
import '../presentation/cubit/comment_cubit.dart' as _i791;

class FeatureCommentPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i201.CommentDataSource>(
        () => _i441.SupabaseCommentDataSource(gh<_i454.SupabaseClient>()));
    gh.lazySingleton<_i999.CommentRepository>(
        () => _i544.CommentRepositoryImpl(gh<_i201.CommentDataSource>()));
    gh.lazySingleton<_i1010.CommentUseCase>(
        () => _i1010.DefaultCommentUseCase(gh<_i999.CommentRepository>()));
    gh.factory<_i791.CommentCubit>(() => _i791.CommentCubit(
          gh<_i1010.CommentUseCase>(),
          gh<_i766.ReactionUseCase>(),
        ));
  }
}
