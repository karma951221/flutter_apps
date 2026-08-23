abstract final class Routes {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const passwordReset = '/password-reset';
  static const home = '/';
  static const postCompose = '/posts/new';
  static const postEdit = '/posts/:postId/edit';
  static const postComments = '/posts/:postId/comments';

  static String postEditPath(String postId) => '/posts/$postId/edit';

  static String postCommentsPath(String postId) => '/posts/$postId/comments';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const userProfile = '/users/:userId';

  static String userProfilePath(String userId) => '/users/$userId';

  /// 미인증 상태에서 접근할 수 있는 경로.
  static const publicRoutes = {signIn, signUp, passwordReset};
}
