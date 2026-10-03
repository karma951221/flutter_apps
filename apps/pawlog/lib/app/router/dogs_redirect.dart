abstract final class PawlogPaths {
  static const feed = '/';
  static const activeWalk = '/walk';
  static const saveWalk = '/walk/save';
  static const walks = '/walks';
  static const dogs = '/dogs';
  static const newDog = '/dogs/new';

  static String walk(String id) => '$walks/$id';
  static String walkEdit(String id) => '$walks/$id/edit';
  static String dog(String id) => '$dogs/$id';
}

/// 반려견이 한 마리도 없으면 등록 화면으로만 다니게 한다.
class DogsRedirect {
  DogsRedirect({required bool hasDogs}) : _hasDogs = hasDogs;

  bool _hasDogs;

  String? resolve(String location) {
    if (!_hasDogs && !location.startsWith(PawlogPaths.dogs)) {
      return PawlogPaths.newDog;
    }
    return null;
  }

  void markHasDogs() => _hasDogs = true;
}
