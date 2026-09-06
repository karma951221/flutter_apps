import '../../features/auth/presentation/bloc/auth_state.dart';
import 'routes.dart';

/// 인증 상태와 현재 위치로 갈 곳을 정한다. null 이면 그대로 둔다.
///
/// `GoRouter.redirect` 에서 뽑아낸 순수 함수다 — 화면 빌더와 DI 없이 표만
/// 검사할 수 있다.
///
/// 가입 화면에서 인증되면 홈이 아니라 프로필 꾸미기로 보낸다. 가입 직후의
/// 빈 홈에는 사용자 것이 하나도 없다 (ux-psychology-review.md 5번). 가입
/// 화면에서 인증 상태가 되는 경로는 가입 성공뿐이므로 위치가 곧 신호다.
String? resolveAuthRedirect({
  required AuthState authState,
  required String location,
}) {
  final isPublic = Routes.publicRoutes.contains(location);
  return switch (authState) {
    AuthUnknown() => location == Routes.splash ? null : Routes.splash,
    AuthUnauthenticated() => isPublic ? null : Routes.signIn,
    AuthAuthenticated() when location == Routes.signUp => Routes.profileSetup,
    AuthAuthenticated() =>
      (isPublic || location == Routes.splash) ? Routes.home : null,
  };
}
