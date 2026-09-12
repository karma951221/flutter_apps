// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'dart:async' as _i687;

import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../data/datasource/language_data_source.dart' as _i697;
import '../data/datasource/preferences_language_data_source.dart' as _i980;
import '../data/datasource/preferences_theme_data_source.dart' as _i835;
import '../data/datasource/theme_data_source.dart' as _i875;
import '../data/repository/language_repository_impl.dart' as _i747;
import '../data/repository/theme_repository_impl.dart' as _i904;
import '../domain/repository/language_repository.dart' as _i512;
import '../domain/repository/theme_repository.dart' as _i984;
import '../domain/usecase/preferences_use_case.dart' as _i679;
import '../presentation/cubit/language_cubit.dart' as _i291;
import '../presentation/cubit/theme_cubit.dart' as _i726;

class FeaturePreferencesPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i697.LanguageDataSource>(() =>
        _i980.PreferencesLanguageDataSource(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i875.ThemeDataSource>(
        () => _i835.PreferencesThemeDataSource(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i512.LanguageRepository>(
        () => _i747.LanguageRepositoryImpl(gh<_i697.LanguageDataSource>()));
    gh.lazySingleton<_i984.ThemeRepository>(
        () => _i904.ThemeRepositoryImpl(gh<_i875.ThemeDataSource>()));
    gh.lazySingleton<_i679.PreferencesUseCase>(
        () => _i679.DefaultPreferencesUseCase(
              gh<_i984.ThemeRepository>(),
              gh<_i512.LanguageRepository>(),
            ));
    gh.factory<_i291.LanguageCubit>(
        () => _i291.LanguageCubit(gh<_i679.PreferencesUseCase>()));
    gh.factory<_i726.ThemeCubit>(
        () => _i726.ThemeCubit(gh<_i679.PreferencesUseCase>()));
  }
}
