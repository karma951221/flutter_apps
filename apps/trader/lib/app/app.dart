import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_preferences/feature_preferences.dart';
import 'package:l10n/l10n.dart';
import 'router/app_router.dart';

class DaylogApp extends StatefulWidget {
  const DaylogApp({super.key});

  @override
  State<DaylogApp> createState() => _DaylogAppState();
}

class _DaylogAppState extends State<DaylogApp> {
  late final AuthBloc _authBloc;
  late final ThemeCubit _themeCubit;
  late final LanguageCubit _languageCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // AuthBloc 은 앱 수명 전체를 살고 라우터가 이걸 참조하므로 여기서 만든다.
    _authBloc = getIt<AuthBloc>()..add(const AuthEvent.started());
    // ThemeCubit 도 앱 수명 전체를 산다. 소비자가 MaterialApp.themeMode 라
    // 라우터·탭보다 위에 있어야 한다.
    _themeCubit = getIt<ThemeCubit>();
    // LanguageCubit 도 같은 이유다 — 소비자가 MaterialApp.locale 이다.
    _languageCubit = getIt<LanguageCubit>();
    _router = createRouter(_authBloc);
  }

  @override
  void dispose() {
    _languageCubit.close();
    _themeCubit.close();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _themeCubit),
        BlocProvider.value(value: _languageCubit),
      ],
      child: BlocBuilder<ThemeCubit, AppThemeMode>(
        builder: (context, mode) => BlocBuilder<LanguageCubit, AppLanguage>(
          builder: (context, language) => MaterialApp.router(
            title: 'daylog',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: mode.themeMode,
            // null 이면 Flutter 가 기기 locale 협상을 한다 (= 시스템 설정).
            locale: language.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            localeListResolutionCallback: resolveAppLocale,
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}

/// 기기의 **선호 언어 목록**을 지원 언어 중 하나로 옮긴다.
///
/// 지원하지 않는 언어를 쓰는 기기에는 한국어보다 **영어**가 낫다는 결정이라
/// 기본 협상에 맡기지 않고 fallback 을 직접 고른다 (계획서).
///
/// 목록 전체를 순서대로 본다. 하나만 받는 `localeResolutionCallback` 으로
/// 두면 기기가 알려준 2순위 이하가 통째로 버려진다 — 기기 언어가
/// `[中文(繁體), 日本語]` 인 사용자는 일본어를 쓸 수 있는데도 영어로
/// 떨어졌다 (2026-08-30 리뷰).
Locale resolveAppLocale(
  List<Locale>? deviceLocales,
  Iterable<Locale> supported,
) {
  for (final device in deviceLocales ?? const <Locale>[]) {
    for (final locale in supported) {
      if (locale.languageCode == device.languageCode) return locale;
    }
  }
  return const Locale('en');
}
