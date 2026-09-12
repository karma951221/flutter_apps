import '../../domain/entity/app_user.dart';
import '../dto/auth_user_dto.dart';

/// data/domain 경계의 인증 사용자 변환.
extension AuthUserDtoMapper on AuthUserDto {
  AppUser toEntity() => AppUser(
    id: id,
    email: email,
    nickname: nickname,
    bio: bio,
    avatarUrl: avatarUrl,
  );
}
