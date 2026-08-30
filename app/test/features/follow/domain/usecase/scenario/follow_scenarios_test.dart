import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/pagination/cursor_page.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/follow/domain/entity/follow_user.dart';
import 'package:daylog/features/follow/domain/repository/follow_repository.dart';
import 'package:daylog/features/follow/domain/usecase/scenario/follow_page_request.dart';
import 'package:daylog/features/follow/domain/usecase/scenario/follow_user_scenario.dart';
import 'package:daylog/features/follow/domain/usecase/scenario/get_followers_scenario.dart';
import 'package:daylog/features/follow/domain/usecase/scenario/get_followings_scenario.dart';
import 'package:daylog/features/follow/domain/usecase/scenario/unfollow_user_scenario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFollowRepository extends Mock implements FollowRepository {}

const _empty = Ok(CursorPage<FollowUser>(items: []));

void main() {
  late _MockFollowRepository repository;

  setUp(() => repository = _MockFollowRepository());

  test('팔로우·해제는 저장소로 그대로 넘어간다', () async {
    when(
      () => repository.followUser('u1'),
    ).thenAnswer((_) async => const Ok(null));
    when(
      () => repository.unfollowUser('u1'),
    ).thenAnswer((_) async => const Ok(null));

    await FollowUserScenario(repository)('u1');
    await UnfollowUserScenario(repository)('u1');

    verify(() => repository.followUser('u1')).called(1);
    verify(() => repository.unfollowUser('u1')).called(1);
  });

  test('팔로워 목록은 방향에 맞는 저장소 메서드를 부른다', () async {
    when(
      () => repository.getFollowers(userId: 'u1', limit: 20, cursor: null),
    ).thenAnswer((_) async => _empty);

    await GetFollowersScenario(repository)(userId: 'u1', limit: 20);

    verify(
      () => repository.getFollowers(userId: 'u1', limit: 20, cursor: null),
    ).called(1);
    verifyNever(
      () => repository.getFollowings(
        userId: any(named: 'userId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    );
  });

  test('팔로잉 목록도 커서를 그대로 넘긴다', () async {
    when(
      () => repository.getFollowings(
        userId: 'u1',
        limit: 20,
        cursor: 'cursor-token',
      ),
    ).thenAnswer((_) async => _empty);

    await GetFollowingsScenario(repository)(
      userId: 'u1',
      limit: 20,
      cursor: 'cursor-token',
    );

    verify(
      () => repository.getFollowings(
        userId: 'u1',
        limit: 20,
        cursor: 'cursor-token',
      ),
    ).called(1);
  });

  test('사용자 식별자가 비면 저장소를 부르지 않는다', () async {
    final result = await GetFollowersScenario(repository)(
      userId: '  ',
      limit: 20,
    );

    expect((result as Err).failure, isA<ValidationFailure>());
    verifyNever(
      () => repository.getFollowers(
        userId: any(named: 'userId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    );
  });

  test('허용 범위를 벗어난 개수는 두 방향 모두 거부한다', () async {
    for (final limit in [0, -1, FollowPageRequest.maxPageSize + 1]) {
      final followers = await GetFollowersScenario(repository)(
        userId: 'u1',
        limit: limit,
      );
      final followings = await GetFollowingsScenario(repository)(
        userId: 'u1',
        limit: limit,
      );

      expect((followers as Err).failure, isA<ValidationFailure>());
      expect((followings as Err).failure, isA<ValidationFailure>());
    }
  });

  test('공백뿐인 커서는 거부한다', () async {
    final result = await GetFollowingsScenario(repository)(
      userId: 'u1',
      limit: 20,
      cursor: '   ',
    );

    expect((result as Err).failure, isA<ValidationFailure>());
  });
}
