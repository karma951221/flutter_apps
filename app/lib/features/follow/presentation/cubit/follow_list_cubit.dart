import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/pagination/cursor_page.dart';
import '../../../../core/result/result.dart';
import '../../domain/entity/follow_user.dart';
import '../../domain/usecase/follow_use_case.dart';
import 'follow_list_state.dart';

/// 팔로워 · 팔로잉 목록을 소유한다.
///
/// 방향만 다르고 읽는 방식이 같아서 cubit 도 하나다 — [load] 가 방향을 받고
/// 이후 [loadMore] 는 그것을 기억한다.
@injectable
class FollowListCubit extends Cubit<FollowListState> {
  FollowListCubit(this._useCase) : super(const FollowListState());

  static const _pageSize = 20;

  final FollowUseCase _useCase;

  String? _userId;
  FollowDirection _direction = FollowDirection.followers;

  Future<void> load({
    required String userId,
    required FollowDirection direction,
  }) async {
    _userId = userId;
    _direction = direction;

    emit(const FollowListState());
    final result = await _fetch();
    if (isClosed) return;

    emit(
      result.when(
        ok: (page) => FollowListState(
          status: FollowListStatus.loaded,
          items: page.items,
          nextCursor: page.nextCursor,
        ),
        err: (failure) =>
            FollowListState(status: FollowListStatus.failure, failure: failure),
      ),
    );
  }

  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) return;
    await load(userId: userId, direction: _direction);
  }

  Future<void> loadMore() async {
    final current = state;
    if (current.status != FollowListStatus.loaded ||
        current.isLoadingMore ||
        !current.canLoadMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));
    final result = await _fetch(cursor: current.nextCursor);
    if (isClosed) return;

    // 요청이 날아가 있는 동안 refresh 가 목록을 갈아치웠을 수 있다. 요청 전
    // 스냅샷이 아니라 지금의 state 위에 붙인다 — FeedCubit 과 같은 이유다.
    final latest = state;
    emit(
      result.when(
        ok: (page) => latest.copyWith(
          items: [...latest.items, ...page.items],
          isLoadingMore: false,
          nextCursor: page.nextCursor,
        ),
        err: (_) => latest.copyWith(isLoadingMore: false),
      ),
    );
  }

  Future<Result<CursorPage<FollowUser>>> _fetch({String? cursor}) {
    final userId = _userId!;
    return switch (_direction) {
      FollowDirection.followers => _useCase.getFollowers(
        userId: userId,
        limit: _pageSize,
        cursor: cursor,
      ),
      FollowDirection.followings => _useCase.getFollowings(
        userId: userId,
        limit: _pageSize,
        cursor: cursor,
      ),
    };
  }
}
