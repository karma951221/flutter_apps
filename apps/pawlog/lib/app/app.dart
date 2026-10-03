import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import 'router/app_router.dart';

class PawlogApp extends StatefulWidget {
  const PawlogApp({super.key});

  @override
  State<PawlogApp> createState() => _PawlogAppState();
}

class _PawlogAppState extends State<PawlogApp> {
  late final Future<GoRouter> _router = _createRouter();

  Future<GoRouter> _createRouter() async {
    final result = await getIt<WalkUseCase>().getDogs();
    final hasDogs = switch (result) {
      Ok(:final value) => value.isNotEmpty,
      Err() => false,
    };
    return createRouter(hasDogs: hasDogs);
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
          onGenerateTitle: (context) =>
              AppLocalizations.of(context).walkAppTitle,
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
