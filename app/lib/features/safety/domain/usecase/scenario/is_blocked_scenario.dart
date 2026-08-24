import '../../../../../core/result/result.dart';
import '../../repository/block_repository.dart';

/// 내가 이 사용자를 차단했는지 확인한다.
///
/// `is_blocked_with()` 를 부르지 않는 이유는 [BlockRepository.isBlocked] 의
/// 문서에 있다 — 프로필 메뉴가 '차단'/'차단 해제' 를 고르는 용도라 내가 건
/// 차단만 봐야 한다.
class IsBlockedScenario {
  const IsBlockedScenario(this._repository);

  final BlockRepository _repository;

  Future<Result<bool>> call(String userId) => _repository.isBlocked(userId);
}
