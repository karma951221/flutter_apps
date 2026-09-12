import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';
import '../../domain/entity/follow_user.dart';

part 'follow_list_state.freezed.dart';

/// 팔로워 · 팔로잉 목록 화면의 상태. 방향은 [FollowDirection] 이 정한다.
@freezed
class FollowListState with _$FollowListState {
  const FollowListState({
    this.status = FollowListStatus.loading,
    this.items = const [],
    this.isLoadingMore = false,
    this.nextCursor,
    this.failure,
  });

  @override
  final FollowListStatus status;
  @override
  final List<FollowUser> items;
  @override
  final bool isLoadingMore;

  /// 다음 페이지 커서. null 이면 마지막 페이지까지 읽었다는 뜻이다.
  @override
  final String? nextCursor;
  @override
  final Failure? failure;

  bool get canLoadMore => nextCursor != null;
}

enum FollowListStatus { loading, loaded, failure }

/// 목록이 어느 방향을 그리는지.
enum FollowDirection {
  /// 이 사용자를 팔로우하는 사람들.
  followers,

  /// 이 사용자가 팔로우하는 사람들.
  followings,
}
