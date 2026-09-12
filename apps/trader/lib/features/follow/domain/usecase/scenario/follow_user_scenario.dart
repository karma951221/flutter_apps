import '../../../../../core/error/failure.dart';
import '../../../../../core/error/failure_code.dart';
import '../../../../../core/result/result.dart';
import '../../repository/follow_repository.dart';

/// 사용자 팔로우.
class FollowUserScenario {
  const FollowUserScenario(this._repository);

  final FollowRepository _repository;

  Future<Result<void>> call(String userId) async {
    // 목록 조회와 같은 검증을 여기서도 한다. 빈 id 를 그대로 내려보내면
    // eq('followee_id', '') 가 22P02 로 튕기고, failureCode 가 없는
    // Failure.server 가 되어 PostgREST 의 영어 문구가 사용자에게 그대로
    // 보인다. FollowPageRequest 를 부르지 않는 것은 그쪽이 목록 결과 타입의
    // Err 를 돌려주기 때문이고, 문구와 코드는 같은 것을 쓴다.
    if (userId.trim().isEmpty) {
      return const Err(
        Failure.validation(
          message: '사용자 식별자가 필요합니다',
          failureCode: FailureCode.followUserIdRequired,
        ),
      );
    }
    return _repository.followUser(userId);
  }
}
