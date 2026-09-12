import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:feature_follow/feature_follow.dart';

part 'profile.freezed.dart';

/// 앱에서 표시하는 공개 프로필.
///
/// Supabase의 응답 형식은 data 계층의 DTO에서만 다루고, 이 타입은
/// presentation과 다른 feature가 안전하게 공유하는 계약이다.
///
/// 팔로우 수와 관계를 함께 담는다 — `profile_details` 뷰가 한 번에 내려주므로
/// 화면이 네 번 조회하지 않는다. `FeedPost` 가 reaction 의 집계를 함께 드는
/// 것과 같은 자리다 (F8, docs/features/follow/plan.md).
@freezed
class Profile with _$Profile {
  @override
  final String id;
  @override
  final String nickname;
  @override
  final String? bio;
  @override
  final String? avatarUrl;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final int followerCount;
  @override
  final int followingCount;
  @override
  final FollowRelation relation;

  const Profile({
    required this.id,
    required this.nickname,
    this.bio,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.followerCount = 0,
    this.followingCount = 0,
    this.relation = const FollowRelation(),
  });
}
