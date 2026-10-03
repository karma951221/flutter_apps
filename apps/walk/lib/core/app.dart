import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../domain/settings/entity/app_settings.dart';
import '../domain/settings/repository/settings_repository.dart';
import '../presentation/alarm/page/alarm_ringing_page.dart';
import '../presentation/settings/cubit/theme_cubit.dart';
import '../presentation/shell/page/main_shell_page.dart';
import '../presentation/theme/walk_theme.dart';
import '../presentation/walk/cubit/step_goal_cubit.dart';
import 'alarm_ring_listener.dart';

/// 울림 화면을 화면 밖(알람 스트림)에서 띄우려고 전역으로 둔다.
final walkNavigatorKey = GlobalKey<NavigatorState>();

class WalkApp extends StatefulWidget {
  const WalkApp({super.key});

  @override
  State<WalkApp> createState() => _WalkAppState();
}

class _WalkAppState extends State<WalkApp> {
  late final _theme = ThemeCubit(getIt<SettingsRepository>());
  late final _goal = StepGoalCubit(getIt<SettingsRepository>());
  late final _ringListener = AlarmRingListener(
    navigatorKey: walkNavigatorKey,
    routeFor: (packageId) => MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => AlarmRingingPage(packageId: packageId),
    ),
  );

  @override
  void initState() {
    super.initState();
    _ringListener.start();
  }

  @override
  void dispose() {
    _ringListener.dispose();
    _theme.close();
    _goal.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _theme),
        BlocProvider.value(value: _goal),
      ],
      child: BlocBuilder<ThemeCubit, AppThemeMode>(
        builder: (context, mode) => MaterialApp(
          navigatorKey: walkNavigatorKey,
          navigatorObservers: [appRouteObserver],
          onGenerateTitle: (context) =>
              AppLocalizations.of(context).walkAppTitle,
          theme: WalkTheme.light(),
          darkTheme: WalkTheme.dark(),
          themeMode: themeModeOf(mode),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          home: const MainShellPage(),
        ),
      ),
    );
  }
}

ThemeMode themeModeOf(AppThemeMode mode) => switch (mode) {
  AppThemeMode.system => ThemeMode.system,
  AppThemeMode.light => ThemeMode.light,
  AppThemeMode.dark => ThemeMode.dark,
};
