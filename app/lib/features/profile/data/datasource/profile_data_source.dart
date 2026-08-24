import '../../domain/entity/avatar_image_draft.dart';
import '../../domain/entity/profile_update.dart';
import '../dto/profile_dto.dart';

/// 프로필 원격 데이터 원천의 계약.
abstract interface class ProfileDataSource {
  Future<ProfileDto> getProfile(String userId);
  Future<ProfileDto?> getMyProfile();
  Future<ProfileDto?> updateMyProfile(ProfileUpdate update);
  Future<bool> isNicknameAvailable(String nickname);

  /// 아바타 이미지를 올리고 공개 URL 을 돌려준다.
  Future<String> uploadAvatar(AvatarImageDraft image);

  /// 공개 URL 이 가리키는 아바타 객체를 지운다. 실패는 삼킨다.
  Future<void> removeAvatar(String? publicUrl);
}
