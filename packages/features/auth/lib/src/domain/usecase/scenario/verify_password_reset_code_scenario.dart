import 'package:core/core.dart';
import '../../repository/auth_repository.dart';

class VerifyPasswordResetCodeScenario {
  const VerifyPasswordResetCodeScenario(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String email, required String code}) =>
      _repository.verifyPasswordResetCode(email: email, code: code);
}
