import 'package:injectable/injectable.dart';

import '../../../../core/result/result.dart';
import '../entity/profile.dart';
import '../entity/profile_update.dart';
import '../repository/profile_repository.dart';
import 'scenario/check_nickname_availability_scenario.dart';
import 'scenario/get_my_profile_scenario.dart';
import 'scenario/get_profile_scenario.dart';
import 'scenario/update_my_profile_scenario.dart';

/// 프로필 feature의 presentation 진입점.
abstract interface class ProfileUseCase {
  Future<Result<Profile>> getProfile(String userId);

  Future<Result<Profile>> getMyProfile();

  Future<Result<Profile>> updateMyProfile(ProfileUpdate update);

  Future<Result<bool>> isNicknameAvailable(String nickname);
}

@LazySingleton(as: ProfileUseCase)
class DefaultProfileUseCase implements ProfileUseCase {
  DefaultProfileUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<Profile>> getProfile(String userId) =>
      GetProfileScenario(_repository)(userId);

  @override
  Future<Result<Profile>> getMyProfile() => GetMyProfileScenario(_repository)();

  @override
  Future<Result<Profile>> updateMyProfile(ProfileUpdate update) =>
      UpdateMyProfileScenario(_repository)(update);

  @override
  Future<Result<bool>> isNicknameAvailable(String nickname) =>
      CheckNicknameAvailabilityScenario(_repository)(nickname);
}
