import 'package:core/core.dart';
import '../../repository/auth_repository.dart';

class SignOutScenario {
  const SignOutScenario(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.signOut();
}
