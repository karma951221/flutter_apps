import 'package:core/core.dart';
import '../../repository/profile_repository.dart';

class CheckNicknameAvailabilityScenario {
  const CheckNicknameAvailabilityScenario(this._repository);

  final ProfileRepository _repository;

  Future<Result<bool>> call(String nickname) =>
      _repository.isNicknameAvailable(nickname);
}
