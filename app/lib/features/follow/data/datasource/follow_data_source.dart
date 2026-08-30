import '../cursor/follow_cursor.dart';
import '../dto/follow_user_dto.dart';

/// 팔로우 원격 데이터 원본.
abstract interface class FollowDataSource {
  Future<void> followUser(String userId);

  Future<void> unfollowUser(String userId);

  /// [userId] 를 팔로우하는 사람들.
  Future<List<FollowUserDto>> getFollowers({
    required String userId,
    required int limit,
    FollowCursor? cursor,
  });

  /// [userId] 가 팔로우하는 사람들.
  Future<List<FollowUserDto>> getFollowings({
    required String userId,
    required int limit,
    FollowCursor? cursor,
  });
}
