abstract final class PawlogPaths {
  static const feed = '/';
  static const activeWalk = '/walk';
  static const saveWalk = '/walk/save';
  static const walks = '/walks';
  static const dogs = '/dogs';
  static const newDog = '/dogs/new';
  static const stats = '/stats';
  static const signIn = '/sign-in';
  static const community = '/community';

  static String walk(String id) => '$walks/$id';
  static String walkEdit(String id) => '$walks/$id/edit';
  static String dog(String id) => '$dogs/$id';

  /// 로그인 뒤 [from] 으로 돌아온다.
  static String signInFrom(String from) =>
      Uri(path: signIn, queryParameters: {'from': from}).toString();
}

/// 반려견이 한 마리도 없으면 등록 화면으로만 다니게 한다.
///
/// 로그인 · 모두의 산책은 예외다 — 반려견과 무관하고, 재설치 직후 둘러보기부터 할 수도 있다.
class DogsRedirect {
  DogsRedirect({required bool hasDogs}) : _hasDogs = hasDogs;

  bool _hasDogs;

  static const _open = {PawlogPaths.signIn, PawlogPaths.community};

  bool get hasDogs => _hasDogs;

  String? resolve(String location) {
    if (!_hasDogs &&
        !location.startsWith(PawlogPaths.dogs) &&
        !_open.contains(location)) {
      return PawlogPaths.newDog;
    }
    return null;
  }

  void markHasDogs() => _hasDogs = true;
}
