import '../../../../../core/result/result.dart';
import '../../repository/follow_repository.dart';

/// 사용자 팔로우.
class FollowUserScenario {
  const FollowUserScenario(this._repository);

  final FollowRepository _repository;

  Future<Result<void>> call(String userId) => _repository.followUser(userId);
}
