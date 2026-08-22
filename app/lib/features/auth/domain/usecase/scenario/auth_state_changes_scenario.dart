import '../../entity/app_user.dart';
import '../../repository/auth_repository.dart';

class AuthStateChangesScenario {
  const AuthStateChangesScenario(this._repository);

  final AuthRepository _repository;

  Stream<AppUser?> call() => _repository.authStateChanges();
}
