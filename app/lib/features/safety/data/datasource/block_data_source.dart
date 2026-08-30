import '../dto/blocked_user_dto.dart';

abstract interface class BlockDataSource {
  /// 사용자를 차단한다.
  Future<void> blockUser(String userId);

  /// 차단을 해제한다.
  Future<void> unblockUser(String userId);

  /// 내가 차단한 사용자 목록을 최근 차단 순으로 돌려준다.
  Future<List<BlockedUserDto>> getBlockedUsers();

  /// 내가 이 사용자를 차단했는지 여부.
  Future<bool> isBlockedByMe(String userId);
}
