import '../../../../../../core/result/result.dart';
import '../../repository/auth_repository.dart';

class UpdatePasswordScenario {
  const UpdatePasswordScenario(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call(String newPassword) =>
      _repository.updatePassword(newPassword);
}
