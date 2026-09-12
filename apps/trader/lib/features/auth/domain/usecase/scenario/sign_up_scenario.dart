import '../../../../../../core/error/failure.dart';
import '../../../../../../core/error/failure_code.dart';
import '../../../../../../core/result/result.dart';
import '../../entity/app_user.dart';
import '../../repository/auth_repository.dart';

/// 닉네임 사전 확인과 가입을 하나의 사용자 동작으로 묶는다.
class SignUpScenario {
  const SignUpScenario(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser>> call({
    required String email,
    required String password,
    required String nickname,
  }) async {
    // DB unique 제약이 최종 방어선이다. 조회 실패만으로 가입을 막지 않는다.
    final available = await _repository.isNicknameAvailable(nickname);
    final taken = available.when(ok: (value) => !value, err: (_) => false);
    if (taken) {
      return const Err(
        Failure.validation(
          message: '이미 사용 중인 닉네임입니다',
          field: 'nickname',
          failureCode: FailureCode.nicknameTaken,
        ),
      );
    }

    return _repository.signUp(
      email: email,
      password: password,
      nickname: nickname,
    );
  }
}
