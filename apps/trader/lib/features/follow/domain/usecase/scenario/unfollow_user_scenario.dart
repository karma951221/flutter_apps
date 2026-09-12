import 'package:core/core.dart';
import '../../repository/follow_repository.dart';

/// 팔로우 해제.
class UnfollowUserScenario {
  const UnfollowUserScenario(this._repository);

  final FollowRepository _repository;

  Future<Result<void>> call(String userId) async {
    // 팔로우와 같은 이유로 여기서 막는다 — 빈 id 는 DB 까지 가면 22P02 의
    // 영어 문구가 되어 돌아온다 (follow_user_scenario.dart 참고).
    if (userId.trim().isEmpty) {
      return const Err(
        Failure.validation(
          message: '사용자 식별자가 필요합니다',
          failureCode: FailureCode.followUserIdRequired,
        ),
      );
    }
    return _repository.unfollowUser(userId);
  }
}
