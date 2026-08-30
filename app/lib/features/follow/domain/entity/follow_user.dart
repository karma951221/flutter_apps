import 'package:freezed_annotation/freezed_annotation.dart';

part 'follow_user.freezed.dart';

/// 팔로워 · 팔로잉 목록의 한 사람.
///
/// 방향에 따라 "상대"가 누구인지만 달라지고 담는 값은 같다 — 팔로워 목록에서는
/// 나를 팔로우한 사람이, 팔로잉 목록에서는 내가 팔로우한 사람이 들어온다.
@freezed
class FollowUser with _$FollowUser {
  @override
  final String id;
  @override
  final String nickname;
  @override
  final String? avatarUrl;

  /// 그 관계가 생긴 시각. 목록의 정렬 기준이자 커서의 한 축이다.
  @override
  final DateTime followedAt;

  const FollowUser({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    required this.followedAt,
  });
}
