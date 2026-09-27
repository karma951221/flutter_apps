import 'package:go_router/go_router.dart';

import '../../presentation/page/commute_home_page.dart';
import '../../presentation/page/commute_settings_page.dart';
import 'settings_redirect.dart';

GoRouter createRouter({required bool settingsComplete}) {
  final settingsRedirect = SettingsRedirect(settingsComplete: settingsComplete);
  return GoRouter(
    initialLocation: CommutePaths.home,
    redirect: (_, state) => settingsRedirect.resolve(state.matchedLocation),
    routes: [
      GoRoute(
        path: CommutePaths.home,
        builder: (context, _) => CommuteHomePage(
          onOpenSettings: () => context.push(CommutePaths.settings),
        ),
      ),
      GoRoute(
        path: CommutePaths.settings,
        builder: (context, _) => CommuteSettingsPage(
          onDone: () {
            settingsRedirect.markComplete();
            context.go(CommutePaths.home);
          },
        ),
      ),
    ],
  );
}
