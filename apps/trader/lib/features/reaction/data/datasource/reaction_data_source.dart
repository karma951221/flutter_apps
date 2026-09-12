import '../../domain/entity/reaction_target.dart';
import '../../domain/entity/reaction_type.dart';

abstract interface class ReactionDataSource {
  Future<void> setReaction(ReactionTarget target, ReactionType type);

  Future<void> clearReaction(ReactionTarget target);
}
