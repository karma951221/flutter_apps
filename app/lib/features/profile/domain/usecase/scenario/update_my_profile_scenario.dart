import '../../../../../core/result/result.dart';
import '../../entity/profile.dart';
import '../../entity/profile_update.dart';
import '../../repository/profile_repository.dart';

class UpdateMyProfileScenario {
  const UpdateMyProfileScenario(this._repository);

  final ProfileRepository _repository;

  Future<Result<Profile>> call(ProfileUpdate update) =>
      _repository.updateMyProfile(update);
}
