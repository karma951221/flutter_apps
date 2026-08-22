import '../../domain/entity/profile_update.dart';
import '../dto/profile_dto.dart';

/// 프로필 원격 데이터 원천의 계약.
abstract interface class ProfileDataSource {
  Future<ProfileDto> getProfile(String userId);
  Future<ProfileDto?> getMyProfile();
  Future<ProfileDto?> updateMyProfile(ProfileUpdate update);
  Future<bool> isNicknameAvailable(String nickname);
}
