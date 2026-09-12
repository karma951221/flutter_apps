import '../../features/auth/presentation/bloc/auth_state.dart';
import 'package:core/core.dart';

/// 인증 상태와 현재 위치로 갈 곳을 정한다. null 이면 그대로 둔다.
///
/// `GoRouter.redirect` 에서 뽑아낸 순수 함수다 — 화면 빌더와 DI 없이 표만
/// 검사할 수 있다.
///
/// 경로는 세 갈래다. 보호 경로(기본) · 공개 경로([Routes.publicRoutes], 인증되면
/// 홈으로 돌려보낸다) · 열린 경로([Routes.openRoutes], 양쪽 다 그대로 둔다).
/// 공유된 판 결과가 열린 경로다 — 같은 링크를 게스트도 로그인 사용자도 열어야
/// 한다.
///
/// 가입 화면에서 인증되면 홈이 아니라 프로필 꾸미기로 보낸다. 가입 직후의
/// 빈 홈에는 사용자 것이 하나도 없다 (ux-psychology-review.md 5번). 가입
/// 화면에서 인증 상태가 되는 경로는 가입 성공뿐이므로 위치가 곧 신호다.
String? resolveAuthRedirect({
  required AuthState authState,
  required String location,
}) {
  final isPublic = Routes.publicRoutes.contains(location);
  // 열린 경로는 미인증에서 로그인으로 보내지 않는다. 인증된 쪽은 아래 마지막
  // 갈래가 이미 그대로 두므로(공개 경로도 스플래시도 아니다) 따로 적지 않는다.
  final isOpen = Routes.isOpenRoute(location);
  return switch (authState) {
    AuthUnknown() => location == Routes.splash ? null : Routes.splash,
    AuthUnauthenticated() => (isPublic || isOpen) ? null : Routes.signIn,
    AuthAuthenticated() when location == Routes.signUp => Routes.profileSetup,
    AuthAuthenticated() =>
      (isPublic || location == Routes.splash) ? Routes.home : null,
  };
}
