import 'package:injectable/injectable.dart';

import 'package:core/core.dart';
import '../entity/reaction_summary.dart';
import '../entity/reaction_target.dart';
import '../entity/reaction_type.dart';
import '../repository/reaction_repository.dart';
import 'scenario/toggle_reaction_scenario.dart';

/// 감정표현 feature 의 presentation 진입점.
abstract interface class ReactionUseCase {
  Future<Result<ReactionSummary>> toggle({
    required ReactionTarget target,
    required ReactionType tapped,
    required ReactionSummary current,
  });
}

@LazySingleton(as: ReactionUseCase)
class DefaultReactionUseCase implements ReactionUseCase {
  DefaultReactionUseCase(this._repository);

  final ReactionRepository _repository;

  @override
  Future<Result<ReactionSummary>> toggle({
    required ReactionTarget target,
    required ReactionType tapped,
    required ReactionSummary current,
  }) => ToggleReactionScenario(
    _repository,
  )(target: target, tapped: tapped, current: current);
}
