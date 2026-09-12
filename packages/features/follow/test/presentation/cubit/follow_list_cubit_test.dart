import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:feature_follow/feature_follow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFollowUseCase extends Mock implements FollowUseCase {}

FollowUser _user(String id) => FollowUser(
  id: id,
  nickname: '사람 $id',
  followedAt: DateTime.utc(2026, 8, 30, 9),
);

void main() {
  late _MockFollowUseCase useCase;

  setUp(() => useCase = _MockFollowUseCase());

  blocTest<FollowListCubit, FollowListState>(
    '팔로워 방향은 팔로워 조회를 부른다',
    build: () {
      when(
        () => useCase.getFollowers(
          userId: any(named: 'userId'),
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer(
        (_) async => Ok(CursorPage<FollowUser>(items: [_user('a')])),
      );
      return FollowListCubit(useCase);
    },
    act: (cubit) =>
        cubit.load(userId: 'u1', direction: FollowDirection.followers),
    expect: () => [
      isA<FollowListState>().having(
        (s) => s.status,
        'status',
        FollowListStatus.loading,
      ),
      isA<FollowListState>()
          .having((s) => s.status, 'status', FollowListStatus.loaded)
          .having((s) => s.items.length, 'items', 1),
    ],
    verify: (_) {
      verify(
        () => useCase.getFollowers(userId: 'u1', limit: 20, cursor: null),
      ).called(1);
      verifyNever(
        () => useCase.getFollowings(
          userId: any(named: 'userId'),
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      );
    },
  );

  blocTest<FollowListCubit, FollowListState>(
    '팔로잉 방향은 팔로잉 조회를 부른다',
    build: () {
      when(
        () => useCase.getFollowings(
          userId: any(named: 'userId'),
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => const Ok(CursorPage<FollowUser>(items: [])));
      return FollowListCubit(useCase);
    },
    act: (cubit) =>
        cubit.load(userId: 'u1', direction: FollowDirection.followings),
    verify: (_) => verify(
      () => useCase.getFollowings(userId: 'u1', limit: 20, cursor: null),
    ).called(1),
  );

  blocTest<FollowListCubit, FollowListState>(
    '실패하면 실패 상태로 남는다',
    build: () {
      when(
        () => useCase.getFollowers(
          userId: any(named: 'userId'),
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => const Err(Failure.network(message: '연결 실패')));
      return FollowListCubit(useCase);
    },
    act: (cubit) =>
        cubit.load(userId: 'u1', direction: FollowDirection.followers),
    expect: () => [
      isA<FollowListState>().having(
        (s) => s.status,
        'status',
        FollowListStatus.loading,
      ),
      isA<FollowListState>()
          .having((s) => s.status, 'status', FollowListStatus.failure)
          .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
    ],
  );

  test('다음 페이지는 커서를 이어 붙인다', () async {
    when(
      () => useCase.getFollowers(userId: 'u1', limit: 20, cursor: null),
    ).thenAnswer(
      (_) async =>
          Ok(CursorPage<FollowUser>(items: [_user('a')], nextCursor: 'c1')),
    );
    when(
      () => useCase.getFollowers(userId: 'u1', limit: 20, cursor: 'c1'),
    ).thenAnswer((_) async => Ok(CursorPage<FollowUser>(items: [_user('b')])));

    final cubit = FollowListCubit(useCase);
    addTearDown(cubit.close);

    await cubit.load(userId: 'u1', direction: FollowDirection.followers);
    await cubit.loadMore();

    expect(cubit.state.items.map((u) => u.id), ['a', 'b']);
    expect(cubit.state.canLoadMore, isFalse);
  });

  test('새로고침이 끼어들면 뒤늦게 온 다음 페이지는 버린다', () async {
    // loadMore 요청이 떠 있는 동안 당겨서 새로고침이 목록을 갈아치우면, 그
    // 응답은 사라진 목록의 뒷부분이다. 지금 목록에 이어 붙이면 그 사이에
    // 있던 사람이 통째로 빠지고 nextCursor 도 옛 경계로 되돌아간다.
    final loadMoreCompleter = Completer<Result<CursorPage<FollowUser>>>();
    var firstPageCount = 0;

    when(
      () => useCase.getFollowers(userId: 'u1', limit: 20, cursor: null),
    ).thenAnswer((_) async {
      firstPageCount += 1;
      // 두 번째 첫 페이지가 새로고침 결과다 — 새로 팔로우한 사람이 맨
      // 앞에 붙으면서 경계가 한 칸 밀린다.
      return firstPageCount == 1
          ? Ok(CursorPage<FollowUser>(items: [_user('a')], nextCursor: 'c1'))
          : Ok(
              CursorPage<FollowUser>(
                items: [_user('새사람'), _user('a')],
                nextCursor: 'c2',
              ),
            );
    });
    when(
      () => useCase.getFollowers(userId: 'u1', limit: 20, cursor: 'c1'),
    ).thenAnswer((_) => loadMoreCompleter.future);

    final cubit = FollowListCubit(useCase);
    addTearDown(cubit.close);

    await cubit.load(userId: 'u1', direction: FollowDirection.followers);
    final loadMoreFuture = cubit.loadMore();
    await cubit.refresh();
    expect(cubit.state.items.map((u) => u.id), ['새사람', 'a']);

    loadMoreCompleter.complete(
      Ok(CursorPage<FollowUser>(items: [_user('b')], nextCursor: 'c1-다음')),
    );
    await loadMoreFuture;

    expect(cubit.state.items.map((u) => u.id), ['새사람', 'a']);
    expect(cubit.state.nextCursor, 'c2');
    expect(cubit.state.isLoadingMore, isFalse);
  });

  test('다음 커서가 없으면 더 읽지 않는다', () async {
    when(
      () => useCase.getFollowers(
        userId: any(named: 'userId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FollowUser>(items: [])));

    final cubit = FollowListCubit(useCase);
    addTearDown(cubit.close);

    await cubit.load(userId: 'u1', direction: FollowDirection.followers);
    await cubit.loadMore();

    verify(
      () => useCase.getFollowers(userId: 'u1', limit: 20, cursor: null),
    ).called(1);
  });
}
