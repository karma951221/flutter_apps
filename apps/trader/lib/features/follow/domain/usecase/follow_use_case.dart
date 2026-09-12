import 'package:injectable/injectable.dart';

import 'package:core/core.dart';
import '../entity/follow_user.dart';
import '../repository/follow_repository.dart';
import 'scenario/follow_user_scenario.dart';
import 'scenario/get_followers_scenario.dart';
import 'scenario/get_followings_scenario.dart';
import 'scenario/unfollow_user_scenario.dart';

/// follow feature 의 presentation 진입점.
abstract interface class FollowUseCase {
  Future<Result<void>> followUser(String userId);

  Future<Result<void>> unfollowUser(String userId);

  Future<Result<CursorPage<FollowUser>>> getFollowers({
    required String userId,
    int limit,
    String? cursor,
  });

  Future<Result<CursorPage<FollowUser>>> getFollowings({
    required String userId,
    int limit,
    String? cursor,
  });
}

@LazySingleton(as: FollowUseCase)
class DefaultFollowUseCase implements FollowUseCase {
  DefaultFollowUseCase(this._repository);

  final FollowRepository _repository;

  @override
  Future<Result<void>> followUser(String userId) =>
      FollowUserScenario(_repository)(userId);

  @override
  Future<Result<void>> unfollowUser(String userId) =>
      UnfollowUserScenario(_repository)(userId);

  @override
  Future<Result<CursorPage<FollowUser>>> getFollowers({
    required String userId,
    int limit = 20,
    String? cursor,
  }) => GetFollowersScenario(_repository)(
    userId: userId,
    limit: limit,
    cursor: cursor,
  );

  @override
  Future<Result<CursorPage<FollowUser>>> getFollowings({
    required String userId,
    int limit = 20,
    String? cursor,
  }) => GetFollowingsScenario(_repository)(
    userId: userId,
    limit: limit,
    cursor: cursor,
  );
}
