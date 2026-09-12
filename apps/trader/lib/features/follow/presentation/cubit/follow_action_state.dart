import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';
import '../../domain/entity/follow_relation.dart';

part 'follow_action_state.freezed.dart';

/// 프로필의 팔로우 버튼 상태.
///
/// 관계와 팔로워 수를 **함께** 든다. 낙관적 업데이트가 둘을 같이 움직여야
/// 하기 때문이다 — 버튼만 바뀌고 수가 그대로면 실패한 것처럼 보인다.
/// 되돌릴 값도 한 벌로 들고 있어야 복원이 어긋나지 않는다.
@freezed
class FollowActionState with _$FollowActionState {
  const FollowActionState({
    this.relation = const FollowRelation(),
    this.followerCount = 0,
    this.isSubmitting = false,
    this.failure,
  });

  @override
  final FollowRelation relation;

  /// 화면에 그리는 팔로워 수. 프로필 조회값에서 시작해 낙관적으로 움직인다.
  @override
  final int followerCount;

  @override
  final bool isSubmitting;

  @override
  final Failure? failure;

  bool get isFollowing => relation.isFollowing;

  bool get isMutual => relation.isMutual;
}
