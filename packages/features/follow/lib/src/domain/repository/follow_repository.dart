import 'package:core/core.dart';
import '../entity/follow_user.dart';

/// 팔로우 저장소.
///
/// 관계 조회(`isFollowing` · `isFollowedBy`)는 여기 없다 — 프로필 조회가
/// `profile_details` 뷰로 함께 내려주므로 화면이 따로 물을 이유가 없다.
/// 차단(`isBlockedByMe`)이 별도 조회인 것과 다른 점이다.
abstract interface class FollowRepository {
  /// 사용자를 팔로우한다. 자기 팔로우 · 중복 · 차단 관계는 서버가 거부한다.
  Future<Result<void>> followUser(String userId);

  /// 팔로우를 해제한다.
  Future<Result<void>> unfollowUser(String userId);

  /// [userId] 를 팔로우하는 사람들을 최근 순으로 돌려준다.
  Future<Result<CursorPage<FollowUser>>> getFollowers({
    required String userId,
    required int limit,
    String? cursor,
  });

  /// [userId] 가 팔로우하는 사람들을 최근 순으로 돌려준다.
  Future<Result<CursorPage<FollowUser>>> getFollowings({
    required String userId,
    required int limit,
    String? cursor,
  });
}
