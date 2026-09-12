import 'package:core/core.dart';
import '../../repository/block_repository.dart';

/// 차단 해제.
class UnblockUserScenario {
  const UnblockUserScenario(this._repository);

  final BlockRepository _repository;

  Future<Result<void>> call(String userId) => _repository.unblockUser(userId);
}
