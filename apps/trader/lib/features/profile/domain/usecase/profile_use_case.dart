import 'package:injectable/injectable.dart';

import '../../../../core/result/result.dart';
import '../entity/avatar_image_draft.dart';
import '../entity/profile.dart';
import '../entity/profile_update.dart';
import '../repository/profile_repository.dart';
import 'scenario/check_nickname_availability_scenario.dart';
import 'scenario/get_my_profile_scenario.dart';
import 'scenario/get_profile_scenario.dart';
import 'scenario/update_avatar_scenario.dart';

/// 프로필 feature의 presentation 진입점.
abstract interface class ProfileUseCase {
  Future<Result<Profile>> getProfile(String userId);

  Future<Result<Profile>> getMyProfile();

  /// 프로필을 저장한다.
  ///
  /// [newAvatar] 를 주면 업로드와 옛 이미지 정리까지 한 흐름으로 처리한다.
  /// 이때 [update]`.avatarUrl` 은 현재 아바타 URL 을 그대로 담아 보낸다.
  Future<Result<Profile>> updateMyProfile(
    ProfileUpdate update, {
    AvatarImageDraft? newAvatar,
  });

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
  Future<Result<Profile>> updateMyProfile(
    ProfileUpdate update, {
    AvatarImageDraft? newAvatar,
  }) => UpdateAvatarScenario(_repository)(update, newAvatar: newAvatar);

  @override
  Future<Result<bool>> isNicknameAvailable(String nickname) =>
      CheckNicknameAvailabilityScenario(_repository)(nickname);
}
