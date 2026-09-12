import '../../../../../core/result/result.dart';
import '../../repository/auth_repository.dart';

/// 가입 전 닉네임 사전 확인.
///
/// 결과는 안내용이다. 최종 판정은 가입할 때 DB 의 유니크 제약이 한다
/// (`SignUpScenario`).
class CheckNicknameAvailabilityScenario {
  const CheckNicknameAvailabilityScenario(this._repository);

  final AuthRepository _repository;

  Future<Result<bool>> call(String nickname) =>
      _repository.isNicknameAvailable(nickname);
}
