import '../../domain/entity/profile.dart';
import '../dto/profile_dto.dart';

/// data/domain 경계의 프로필 변환.
extension ProfileDtoMapper on ProfileDto {
  Profile toEntity() => Profile(
    id: id,
    nickname: nickname,
    bio: bio,
    avatarUrl: avatarUrl,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
