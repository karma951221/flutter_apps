import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:core/core.dart';
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

  /// 지금 화면이 기다리고 있는 조회의 세대 번호.
  ///
  /// [load] 가 값을 올리고, 요청을 띄우는 쪽은 보내기 전에 잡아 두었다가
  /// 응답 시점에 달라졌으면 버린다 — [FeedCubit] 과 같은 장치다.
  int _generation = 0;

  Future<void> load({
    required String userId,
    required FollowDirection direction,
  }) async {
    _userId = userId;
    _direction = direction;

    final generation = ++_generation;
    emit(const FollowListState());
    final result = await _fetch();
    if (isClosed || generation != _generation) return;

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

    final generation = _generation;
    emit(current.copyWith(isLoadingMore: true));
    final result = await _fetch(cursor: current.nextCursor);
    // 요청이 날아가 있는 동안 refresh 가 목록을 갈아치웠다면, 이 페이지는
    // 사라진 목록의 뒷부분이다. 지금 목록에 이어 붙이면 그 사이에 있던 사람이
    // 통째로 빠지고 nextCursor 도 옛 경계로 되돌아간다 — 병합이 아니라
    // 버려야 하는 응답이다. 새 목록의 다음 페이지는 사용자가 다시 바닥에
    // 닿을 때 새 커서로 읽는다.
    if (isClosed || generation != _generation) return;

    // 세대가 같아도 다른 mutator 가 state 를 바꿨을 수 있으므로 요청 전
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
