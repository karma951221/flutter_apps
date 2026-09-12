import 'package:core/core.dart';
import '../../entity/profile.dart';
import '../../repository/profile_repository.dart';

class GetMyProfileScenario {
  const GetMyProfileScenario(this._repository);

  final ProfileRepository _repository;

  Future<Result<Profile>> call() => _repository.getMyProfile();
}
