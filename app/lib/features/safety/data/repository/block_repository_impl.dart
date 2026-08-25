import 'package:injectable/injectable.dart';

import '../../../../core/result/result.dart';
import '../../domain/entity/blocked_user.dart';
import '../../domain/repository/block_repository.dart';
import '../datasource/block_data_source.dart';
import '../mapper/blocked_user_mapper.dart';
import 'block_repository_error_handler.dart';

@LazySingleton(as: BlockRepository)
class BlockRepositoryImpl
    with BlockRepositoryErrorHandler
    implements BlockRepository {
  BlockRepositoryImpl(this._dataSource);

  final BlockDataSource _dataSource;

  @override
  Future<Result<void>> blockUser(String userId) =>
      guard(() => _dataSource.blockUser(userId));

  @override
  Future<Result<void>> unblockUser(String userId) =>
      guard(() => _dataSource.unblockUser(userId));

  @override
  Future<Result<List<BlockedUser>>> getBlockedUsers() => guard(() async {
    final dtos = await _dataSource.getBlockedUsers();
    return dtos.map((dto) => dto.toEntity()).toList();
  });

  @override
  Future<Result<bool>> isBlockedByMe(String userId) =>
      guard(() => _dataSource.isBlockedByMe(userId));
}
