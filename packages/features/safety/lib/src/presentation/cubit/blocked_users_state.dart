import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';
import '../../domain/entity/blocked_user.dart';

part 'blocked_users_state.freezed.dart';

/// 차단 목록 화면의 상태. 커서를 쓰지 않는다 (apps/trader/docs/features/safety/plan-block.md).
@freezed
class BlockedUsersState with _$BlockedUsersState {
  const BlockedUsersState({
    this.status = BlockedUsersStatus.loading,
    this.items = const [],
    this.failure,
  });

  @override
  final BlockedUsersStatus status;

  @override
  final List<BlockedUser> items;

  @override
  final Failure? failure;
}

enum BlockedUsersStatus { loading, loaded, failure }
