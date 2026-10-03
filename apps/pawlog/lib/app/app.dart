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
          // 부팅(DI · 첫 조회)이 실패하면 스피너가 영원히 돌지 않게 원인을 띄운다.
          // 이 시점엔 l10n 이 없어 공통 안내 위젯 대신 오류 문자열을 그대로 보인다.
          final error = snapshot.error;
          return MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: error == null
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: SelectableText('$error'),
                      ),
              ),
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
