import 'package:injectable/injectable.dart';

import '../../../../core/result/result.dart';
import '../entity/app_user.dart';
import '../repository/auth_repository.dart';
import 'scenario/auth_state_changes_scenario.dart';
import 'scenario/check_nickname_availability_scenario.dart';
import 'scenario/current_user_scenario.dart';
import 'scenario/delete_account_scenario.dart';
import 'scenario/send_password_reset_code_scenario.dart';
import 'scenario/sign_in_scenario.dart';
import 'scenario/sign_out_scenario.dart';
import 'scenario/sign_up_scenario.dart';
import 'scenario/update_password_scenario.dart';
import 'scenario/verify_password_reset_code_scenario.dart';

/// 인증 feature의 presentation 진입점.
///
/// Bloc/Cubit은 이 facade 하나만 주입받는다. 사용자 동작별 흐름은 scenario 파일에
/// 두어, 기능이 늘어도 presentation의 의존성 수가 증가하지 않게 한다.
abstract interface class AuthUseCase {
  Stream<AppUser?> authStateChanges();

  /// 지금 세션의 사용자를 저장소에서 다시 읽는다. 미인증이면 null.
  Future<AppUser?> currentUser();

  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  });

  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
    required String nickname,
  });

  /// 가입 전 닉네임 사용 가능 여부. 안내용이며 최종 판정은 DB 제약이 한다.
  Future<Result<bool>> isNicknameAvailable(String nickname);

  Future<Result<void>> signOut();

  /// 계정과 계정에 딸린 모든 것을 지운다. 성공하면 세션도 함께 사라진다.
  Future<Result<void>> deleteAccount();

  Future<Result<void>> sendPasswordResetCode(String email);

  Future<Result<void>> verifyPasswordResetCode({
    required String email,
    required String code,
  });

  Future<Result<void>> updatePassword(String newPassword);
}

@LazySingleton(as: AuthUseCase)
class DefaultAuthUseCase implements AuthUseCase {
  DefaultAuthUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Stream<AppUser?> authStateChanges() =>
      AuthStateChangesScenario(_repository)();

  @override
  Future<AppUser?> currentUser() => CurrentUserScenario(_repository)();

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) => SignInScenario(_repository)(email: email, password: password);

  @override
  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
    required String nickname,
  }) => SignUpScenario(_repository)(
    email: email,
    password: password,
    nickname: nickname,
  );

  @override
  Future<Result<bool>> isNicknameAvailable(String nickname) =>
      CheckNicknameAvailabilityScenario(_repository)(nickname);

  @override
  Future<Result<void>> signOut() => SignOutScenario(_repository)();

  @override
  Future<Result<void>> deleteAccount() => DeleteAccountScenario(_repository)();

  @override
  Future<Result<void>> sendPasswordResetCode(String email) =>
      SendPasswordResetCodeScenario(_repository)(email);

  @override
  Future<Result<void>> verifyPasswordResetCode({
    required String email,
    required String code,
  }) => VerifyPasswordResetCodeScenario(_repository)(email: email, code: code);

  @override
  Future<Result<void>> updatePassword(String newPassword) =>
      UpdatePasswordScenario(_repository)(newPassword);
}
