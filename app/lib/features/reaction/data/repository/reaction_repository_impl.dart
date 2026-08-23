import 'package:injectable/injectable.dart';

import '../../../../core/result/result.dart';
import '../../domain/entity/reaction_target.dart';
import '../../domain/entity/reaction_type.dart';
import '../../domain/repository/reaction_repository.dart';
import '../datasource/reaction_data_source.dart';
import 'reaction_repository_error_handler.dart';

@LazySingleton(as: ReactionRepository)
class ReactionRepositoryImpl
    with ReactionRepositoryErrorHandler
    implements ReactionRepository {
  ReactionRepositoryImpl(this._dataSource);

  final ReactionDataSource _dataSource;

  @override
  Future<Result<void>> setReaction(ReactionTarget target, ReactionType type) =>
      guard(() => _dataSource.setReaction(target, type));

  @override
  Future<Result<void>> clearReaction(ReactionTarget target) =>
      guard(() => _dataSource.clearReaction(target));
}
