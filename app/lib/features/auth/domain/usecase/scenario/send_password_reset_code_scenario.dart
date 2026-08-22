import '../../../../../../core/result/result.dart';
import '../../repository/auth_repository.dart';

class SendPasswordResetCodeScenario {
  const SendPasswordResetCodeScenario(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call(String email) =>
      _repository.sendPasswordResetCode(email);
}
