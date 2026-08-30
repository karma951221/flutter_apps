import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/pagination/cursor_page.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/follow/domain/entity/follow_user.dart';
import 'package:daylog/features/follow/domain/usecase/follow_use_case.dart';
import 'package:daylog/features/follow/presentation/cubit/follow_list_cubit.dart';
import 'package:daylog/features/follow/presentation/cubit/follow_list_state.dart';
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
