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

  /// 미인증 상태에서 접근할 수 있는 경로.
  static const publicRoutes = {signIn, signUp, passwordReset, explore};
}
