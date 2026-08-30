import '../../../../../core/result/result.dart';
import '../../repository/follow_repository.dart';

/// 팔로우 해제.
class UnfollowUserScenario {
  const UnfollowUserScenario(this._repository);

  final FollowRepository _repository;

  Future<Result<void>> call(String userId) => _repository.unfollowUser(userId);
}
