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
import '../../features/chat/presentation/page/chat_explore_page.dart';
import '../../features/chat/presentation/page/chat_room_page.dart';
import '../../features/chat/presentation/page/create_room_page.dart';
import '../../features/comment/presentation/page/post_comments_page.dart';
import '../../features/home/presentation/page/home_shell_page.dart';
import '../../features/post/domain/entity/post.dart';
import '../../features/post/presentation/cubit/post_cubit.dart';
import '../../features/post/presentation/page/post_editor_page.dart';
import '../../features/follow/presentation/cubit/follow_list_state.dart';
import '../../features/follow/presentation/page/follow_list_page.dart';
import '../../features/profile/presentation/page/edit_profile_page.dart';
import '../../features/profile/presentation/page/profile_page.dart';
import '../../features/safety/presentation/page/blocked_users_page.dart';
import '../../features/settings/presentation/page/account_settings_page.dart';
import '../../features/settings/presentation/page/change_password_page.dart';
import '../../features/settings/presentation/page/settings_page.dart';
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
      // 홈은 셸이다. 피드·프로필·설정은 탭으로 살아 있고, 그 위에 얹히는
      // 화면(작성 · 편집 · 댓글)은 아래의 독립 라우트로 push 된다.
      GoRoute(path: Routes.home, builder: (_, _) => const HomeShellPage()),
      GoRoute(
        path: Routes.postCompose,
        builder: (_, _) => BlocProvider(
          create: (_) => getIt<PostCubit>(),
          child: const PostEditorPage(),
        ),
      ),
      GoRoute(
        path: Routes.postEdit,
        builder: (_, state) => BlocProvider(
          create: (_) => getIt<PostCubit>(),
          child: PostEditorPage(post: state.extra as Post?),
        ),
      ),
      GoRoute(
        path: Routes.postComments,
        builder: (_, state) => PostCommentsPage(
          postId: state.pathParameters['postId']!,
          // 화면을 나갈 때 돌려줄 최종 댓글 수의 출발점. 목록이 이미 아는 값을
          // 넘기므로 상세를 열자마자 개수를 다시 조회하지 않는다.
          initialCount: state.extra as int? ?? 0,
        ),
      ),
      GoRoute(path: Routes.profile, builder: (_, _) => const ProfilePage()),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsPage()),
      // /chat/:roomId 보다 먼저 와야 한다. 뒤에 두면 'explore' 와 'new' 가
      // roomId 로 잡힌다.
      GoRoute(
        path: Routes.chatExplore,
        builder: (_, _) => const ChatExplorePage(),
      ),
      GoRoute(
        path: Routes.chatCreate,
        builder: (_, _) => const CreateRoomPage(),
      ),
      GoRoute(
        path: Routes.chatRoom,
        builder: (_, state) => ChatRoomPage(
          roomId: state.pathParameters['roomId']!,
          title: state.extra as String?,
        ),
      ),
      GoRoute(
        path: Routes.accountSettings,
        builder: (_, _) => const AccountSettingsPage(),
      ),
      GoRoute(
        path: Routes.changePassword,
        builder: (_, _) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: Routes.blockedUsers,
        builder: (_, _) => const BlockedUsersPage(),
      ),
      GoRoute(
        path: Routes.userProfile,
        builder: (_, state) =>
            ProfilePage(userId: state.pathParameters['userId']!),
      ),
      GoRoute(
        path: Routes.profileEdit,
        builder: (_, _) => const EditProfilePage(),
      ),
      GoRoute(
        path: Routes.userFollowers,
        builder: (_, state) => FollowListPage(
          userId: state.pathParameters['userId']!,
          direction: FollowDirection.followers,
        ),
      ),
      GoRoute(
        path: Routes.userFollowings,
        builder: (_, state) => FollowListPage(
          userId: state.pathParameters['userId']!,
          direction: FollowDirection.followings,
        ),
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
