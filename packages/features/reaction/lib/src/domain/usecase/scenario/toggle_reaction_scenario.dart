import 'package:core/core.dart';
import '../../entity/reaction_summary.dart';
import '../../entity/reaction_target.dart';
import '../../entity/reaction_type.dart';
import '../../repository/reaction_repository.dart';

/// 감정 하나를 누른 결과를 저장하고 다음 상태를 돌려준다.
///
/// 현재 상태를 인자로 받는 이유: "같은 것을 다시 누르면 취소"를 판정하려면
/// 현재 값이 필요한데, DB 에서 다시 읽으면 왕복이 하나 늘고 낙관적 업데이트와
/// 상충한다. 정책은 domain 이 갖고 상태는 호출자가 준다.
class ToggleReactionScenario {
  const ToggleReactionScenario(this._repository);

  final ReactionRepository _repository;

  Future<Result<ReactionSummary>> call({
    required ReactionTarget target,
    required ReactionType tapped,
    required ReactionSummary current,
  }) async {
    final next = current.toggled(tapped);

    final saved = next.mine == null
        ? await _repository.clearReaction(target)
        : await _repository.setReaction(target, tapped);

    return saved.when(ok: (_) => Ok(next), err: Err.new);
  }
}
