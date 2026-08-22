abstract final class Routes {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const passwordReset = '/password-reset';
  static const home = '/';
  static const feedCompose = '/feed/compose';
  static const feedEdit = '/feed/:postId/edit';

  static String feedEditPath(String postId) => '/feed/$postId/edit';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';

  /// 미인증 상태에서 접근할 수 있는 경로.
  static const publicRoutes = {signIn, signUp, passwordReset};
}
