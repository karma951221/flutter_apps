import '../../domain/entity/follow_user.dart';
import '../dto/follow_user_dto.dart';

/// data/domain 경계의 팔로우 사용자 변환.
extension FollowUserDtoMapper on FollowUserDto {
  FollowUser toEntity() => FollowUser(
    id: id,
    nickname: nickname,
    avatarUrl: avatarUrl,
    followedAt: createdAt,
  );
}
