import 'package:core/core.dart';
import '../entity/reaction_target.dart';
import '../entity/reaction_type.dart';

/// 감정표현 저장소.
///
/// 조회는 여기 없다. 개수와 내 반응은 목록 뷰가 항목과 함께 내려준다 —
/// 항목마다 다시 조회하면 그게 없애려던 N+1 이다.
abstract interface class ReactionRepository {
  /// 감정을 남기거나 다른 감정으로 바꾼다. 전환도 한 번의 왕복이다.
  Future<Result<void>> setReaction(ReactionTarget target, ReactionType type);

  /// 내 감정을 취소한다.
  Future<Result<void>> clearReaction(ReactionTarget target);
}
