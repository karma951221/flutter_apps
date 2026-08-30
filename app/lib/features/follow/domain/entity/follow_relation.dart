import 'package:freezed_annotation/freezed_annotation.dart';

part 'follow_relation.freezed.dart';

/// 나와 어떤 사용자 사이의 팔로우 관계.
///
/// 두 방향을 따로 들고 맞팔은 파생값으로 둔다. DB 도 같은 모양이다 — 맞팔은
/// 반대 방향 행이 하나 더 있는 것일 뿐이라 상태를 따로 저장하지 않는다
/// (docs/features/follow/plan.md).
@freezed
class FollowRelation with _$FollowRelation {
  @override
  final bool isFollowing;
  @override
  final bool isFollowedBy;

  const FollowRelation({
    this.isFollowing = false,
    this.isFollowedBy = false,
  });

  /// 서로 팔로우 중이다.
  bool get isMutual => isFollowing && isFollowedBy;
}
