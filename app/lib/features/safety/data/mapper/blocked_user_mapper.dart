import '../../domain/entity/blocked_user.dart';
import '../dto/blocked_user_dto.dart';

/// data/domain 경계의 차단 사용자 변환.
extension BlockedUserDtoMapper on BlockedUserDto {
  BlockedUser toEntity() => BlockedUser(
    id: id,
    nickname: nickname,
    avatarUrl: avatarUrl,
    blockedAt: createdAt,
  );
}
