import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'settings_redirect.dart';

GoRouter createRouter({required bool settingsComplete}) {
  final settingsRedirect = SettingsRedirect(settingsComplete: settingsComplete);
  return GoRouter(
    initialLocation: CommutePaths.home,
    redirect: (_, state) => settingsRedirect.resolve(state.matchedLocation),
    routes: [
      GoRoute(
        path: CommutePaths.home,
        builder: (_, _) => const Scaffold(
          key: Key('commute-home-placeholder'),
          body: Placeholder(),
        ),
      ),
      GoRoute(
        path: CommutePaths.settings,
        builder: (context, _) => Scaffold(
          key: const Key('commute-settings-placeholder'),
          body: Column(
            children: [
              const Expanded(child: Placeholder()),
              IconButton(
                onPressed: () {
                  settingsRedirect.markComplete();
                  context.go(CommutePaths.home);
                },
                icon: const Icon(Icons.done),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
