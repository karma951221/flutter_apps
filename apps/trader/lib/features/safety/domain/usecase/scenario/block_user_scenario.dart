import 'package:core/core.dart';
import '../../repository/block_repository.dart';

/// 사용자 차단.
class BlockUserScenario {
  const BlockUserScenario(this._repository);

  final BlockRepository _repository;

  Future<Result<void>> call(String userId) => _repository.blockUser(userId);
}
