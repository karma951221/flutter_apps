abstract final class Routes {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const passwordReset = '/password-reset';

  /// 비로그인 읽기 전용 피드. 로그인 화면의 "먼저 둘러보기" 로 들어온다.
  static const explore = '/explore';
  static const home = '/';
  static const postCompose = '/posts/new';
  static const postEdit = '/posts/:postId/edit';
  static const postComments = '/posts/:postId/comments';

  static String postEditPath(String postId) => '/posts/$postId/edit';

  static String postCommentsPath(String postId) => '/posts/$postId/comments';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';

  /// 가입 직후 한 번 지나가는 프로필 꾸미기. 보호 경로다.
  static const profileSetup = '/profile/setup';
  static const chat = '/chat';
  static const chatExplore = '/chat/explore';
  static const chatCreate = '/chat/new';
  static const chatRoom = '/chat/:roomId';

  static String chatRoomPath(String roomId) => '/chat/$roomId';
  static const settings = '/settings';
  static const accountSettings = '/settings/account';
  static const blockedUsers = '/settings/blocked';
  static const changePassword = '/settings/account/password';
  static const userProfile = '/users/:userId';
  static const userFollowers = '/users/:userId/followers';
  static const userFollowings = '/users/:userId/followings';

  static String userProfilePath(String userId) => '/users/$userId';

  static String userFollowersPath(String userId) => '/users/$userId/followers';

  static String userFollowingsPath(String userId) =>
      '/users/$userId/followings';

  /// 판 진행 화면. 라우트 등록은 화면을 만드는 쪽(F10 Task 9)이 한다.
  static const tradeSession = '/trade/:sessionId';

  /// 끝난 판의 결과. 공유 링크가 가리키는 자리라 로그인 여부와 무관하게 열린다.
  static const tradeResult = '/trade/:sessionId/result';

  static String tradeSessionPath(String sessionId) => '/trade/$sessionId';

  static String tradeResultPath(String sessionId) => '/trade/$sessionId/result';

  /// 미인증 상태에서 접근할 수 있는 경로.
  ///
  /// 인증된 사용자는 여기 있으면 홈으로 돌아간다 — 로그인·가입·둘러보기는
  /// 이미 로그인한 사람이 머물 자리가 아니기 때문이다.
  static const publicRoutes = {signIn, signUp, passwordReset, explore};

  /// 로그인 여부와 무관하게 그대로 열리는 경로 패턴.
  ///
  /// [publicRoutes] 와 다르다. 공유된 결과 링크는 게스트에게도, 로그인
  /// 사용자에게도 **같은 화면**이어야 해서 어느 쪽도 돌려보내지 않는다.
  /// 경로에 id 가 들어가 상수 집합으로는 못 담으므로 패턴으로 둔다.
  static final openRoutes = <RegExp>[RegExp(r'^/trade/[^/]+/result$')];

  /// [location] 이 [openRoutes] 중 하나에 해당하는지.
  static bool isOpenRoute(String location) =>
      openRoutes.any((pattern) => pattern.hasMatch(location));
}
