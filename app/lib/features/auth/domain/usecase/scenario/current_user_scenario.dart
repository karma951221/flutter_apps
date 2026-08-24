import '../../entity/app_user.dart';
import '../../repository/auth_repository.dart';

/// 저장소에서 현재 사용자를 다시 읽는다.
///
/// 프로필을 수정한 뒤처럼, 세션은 그대로인데 profiles 행만 바뀐 경우에 쓴다.
class CurrentUserScenario {
  const CurrentUserScenario(this._repository);

  final AuthRepository _repository;

  Future<AppUser?> call() => _repository.currentUser();
}
