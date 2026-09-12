import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';
import 'package:feature_auth/feature_auth.dart';
import '../../features/chat/presentation/page/chat_explore_page.dart';
import '../../features/chat/presentation/page/chat_room_page.dart';
import '../../features/chat/presentation/page/create_room_page.dart';
import '../../features/comment/presentation/page/post_comments_page.dart';
import '../../features/feed/presentation/page/guest_feed_page.dart';
import '../../features/home/presentation/page/home_shell_page.dart';
import '../../features/post/domain/entity/post.dart';
import '../../features/post/presentation/cubit/post_cubit.dart';
import '../../features/post/presentation/page/post_editor_page.dart';
import 'package:feature_follow/feature_follow.dart';
import '../../features/profile/presentation/page/edit_profile_page.dart';
import '../../features/profile/presentation/page/profile_page.dart';
import 'package:feature_safety/feature_safety.dart';
import '../../features/settings/presentation/page/account_settings_page.dart';
import '../../features/settings/presentation/page/change_password_page.dart';
import '../../features/settings/presentation/page/settings_page.dart';
import 'package:feature_trade/feature_trade.dart';
import 'auth_redirect.dart';

/// 인증 게이트.
///
/// 화면들이 각자 "로그인했나?"를 확인하지 않는다. 판단은 여기 한 곳에서만 한다.
/// 새 화면을 추가할 때 보호 로직을 빠뜨릴 여지를 없애기 위해서다.
GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: Routes.splash,
    // 화면 위에 얹은 화면이 걷히는 순간을 듣는 곳(예: 모의투자 홈).
    observers: [appRouteObserver],
    refreshListenable: _BlocRefreshNotifier(authBloc.stream),
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) => resolveAuthRedirect(
      authState: authBloc.state,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInPage()),
      GoRoute(path: Routes.signUp, builder: (_, _) => const SignUpPage()),
      GoRoute(
        path: Routes.passwordReset,
        builder: (_, _) => const PasswordResetPage(),
      ),
      GoRoute(path: Routes.explore, builder: (_, _) => const GuestFeedPage()),
      // 홈은 셸이다. 피드·프로필·설정은 탭으로 살아 있고, 그 위에 얹히는
      // 화면(작성 · 편집 · 댓글)은 아래의 독립 라우트로 push 된다.
      GoRoute(path: Routes.home, builder: (_, _) => const HomeShellPage()),
      GoRoute(
        path: Routes.postCompose,
        // extra 는 결과 화면의 "공유하기"가 들려 보낸 판 결과다. 그냥 들어오면
        // null 이고 평소의 작성 화면이 된다. JSON 호환 Map 으로 오므로(go_router
        // 의 codec 경고를 피하려고 TradeResultSummary 대신 Map 을 넘긴다)
        // 여기서 되돌린다 — 형태가 아니면 fromMap 이 null 을 준다.
        builder: (_, state) => BlocProvider(
          create: (_) => getIt<PostCubit>(),
          child: PostEditorPage(
            tradeResult: TradeResultSummary.fromMap(state.extra),
          ),
        ),
      ),
      GoRoute(
        path: Routes.postEdit,
        builder: (_, state) => BlocProvider(
          create: (_) => getIt<PostCubit>(),
          child: PostEditorPage(post: Post.fromMap(state.extra)),
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
          args: ChatRoomPageArgs.fromMap(state.extra),
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
        path: Routes.profileSetup,
        builder: (_, _) => const EditProfilePage(isSetup: true),
      ),
      GoRoute(
        path: Routes.userFollowers,
        builder: (_, state) => FollowListPage(
          userId: state.pathParameters['userId']!,
          direction: FollowDirection.followers,
        ),
      ),
      // `/trade/:sessionId` 와 `/trade/:sessionId/result` 는 세그먼트 수가
      // 달라 서로를 가리지 않는다 — `result` 가 sessionId 로 잡히지 않는다는
      // 뜻이다. 순서에 기대지 않지만, 그래도 두 라우트를 붙여 둔다.
      GoRoute(
        path: Routes.tradeSession,
        builder: (_, state) =>
            TradeSessionPage(sessionId: state.pathParameters['sessionId']!),
      ),
      // 결과는 공유 링크가 가리키는 자리라 로그인 여부와 무관하게 열린다 —
      // 리다이렉트 예외는 resolveAuthRedirect 에 있다.
      GoRoute(
        path: Routes.tradeResult,
        builder: (_, state) =>
            TradeResultPage(sessionId: state.pathParameters['sessionId']!),
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
