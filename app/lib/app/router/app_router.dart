import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/page/password_reset_page.dart';
import '../../features/auth/presentation/page/sign_in_page.dart';
import '../../features/auth/presentation/page/sign_up_page.dart';
import '../../features/auth/presentation/page/splash_page.dart';
import '../../features/feed/domain/entity/feed_post.dart';
import '../../features/feed/presentation/page/feed_editor_page.dart';
import '../../features/feed/presentation/page/feed_page.dart';
import '../../features/feed/presentation/cubit/feed_cubit.dart';
import '../../features/profile/presentation/page/edit_profile_page.dart';
import '../../features/profile/presentation/page/profile_page.dart';
import 'routes.dart';

/// 인증 게이트.
///
/// 화면들이 각자 "로그인했나?"를 확인하지 않는다. 판단은 여기 한 곳에서만 한다.
/// 새 화면을 추가할 때 보호 로직을 빠뜨릴 여지를 없애기 위해서다.
GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: _BlocRefreshNotifier(authBloc.stream),
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final authState = authBloc.state;
      final location = state.matchedLocation;
      final isPublic = Routes.publicRoutes.contains(location);

      return switch (authState) {
        // 아직 세션을 읽는 중 — 스플래시에 머문다.
        AuthUnknown() => location == Routes.splash ? null : Routes.splash,

        // 미인증 — 공개 경로가 아니면 로그인으로.
        AuthUnauthenticated() => isPublic ? null : Routes.signIn,

        // 인증됨 — 로그인/가입/스플래시에 있으면 홈으로.
        AuthAuthenticated() =>
          (isPublic || location == Routes.splash) ? Routes.home : null,
      };
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInPage()),
      GoRoute(path: Routes.signUp, builder: (_, _) => const SignUpPage()),
      GoRoute(
        path: Routes.passwordReset,
        builder: (_, _) => const PasswordResetPage(),
      ),
      GoRoute(path: Routes.home, builder: (_, _) => const FeedPage()),
      GoRoute(
        path: Routes.feedCompose,
        builder: (_, _) => BlocProvider(
          create: (_) => getIt<FeedCubit>(),
          child: const FeedEditorPage(),
        ),
      ),
      GoRoute(
        path: Routes.feedEdit,
        builder: (_, state) => BlocProvider(
          create: (_) => getIt<FeedCubit>(),
          child: FeedEditorPage(post: state.extra as FeedPost?),
        ),
      ),
      GoRoute(path: Routes.profile, builder: (_, _) => const ProfilePage()),
      GoRoute(
        path: Routes.profileEdit,
        builder: (_, _) => const EditProfilePage(),
      ),
    ],
  );
}

/// bloc 상태가 바뀌면 go_router 에게 재평가를 요청한다.
class _BlocRefreshNotifier extends ChangeNotifier {
  _BlocRefreshNotifier(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
