import '../../../../../../core/result/result.dart';
import '../../entity/app_user.dart';
import '../../repository/auth_repository.dart';

class SignInScenario {
  const SignInScenario(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser>> call({
    required String email,
    required String password,
  }) => _repository.signIn(email: email, password: password);
}
