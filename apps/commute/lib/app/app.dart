import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_commute/feature_commute.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import 'router/app_router.dart';

class CommuteApp extends StatefulWidget {
  const CommuteApp({super.key});

  @override
  State<CommuteApp> createState() => _CommuteAppState();
}

class _CommuteAppState extends State<CommuteApp> {
  late final Future<GoRouter> _router = _createRouter();

  Future<GoRouter> _createRouter() async {
    final result = await getIt<CommuteUseCase>().getSettings();
    final isComplete = switch (result) {
      Ok(:final value) => value.isComplete,
      Err() => false,
    };
    return createRouter(settingsComplete: isComplete);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _router,
      builder: (context, snapshot) {
        final router = snapshot.data;
        if (router == null) {
          return MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return MaterialApp.router(
          title: 'commute',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          routerConfig: router,
        );
      },
    );
  }
}
