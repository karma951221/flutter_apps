import 'package:core/core.dart';
import '../../entity/blocked_user.dart';
import '../../repository/block_repository.dart';

/// 차단한 사용자 목록 조회.
class GetBlockedUsersScenario {
  const GetBlockedUsersScenario(this._repository);

  final BlockRepository _repository;

  Future<Result<List<BlockedUser>>> call() => _repository.getBlockedUsers();
}
