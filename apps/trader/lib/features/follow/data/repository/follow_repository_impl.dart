import 'package:injectable/injectable.dart';

import 'package:core/core.dart';
import '../../domain/entity/follow_user.dart';
import '../../domain/repository/follow_repository.dart';
import '../cursor/follow_cursor.dart';
import '../datasource/follow_data_source.dart';
import '../dto/follow_user_dto.dart';
import '../mapper/follow_user_mapper.dart';

/// FollowDataSource 를 domain Repository 계약으로 변환하는 구현체.
@LazySingleton(as: FollowRepository)
class FollowRepositoryImpl
    with RepositoryErrorHandler
    implements FollowRepository {
  FollowRepositoryImpl(this._dataSource);

  final FollowDataSource _dataSource;

  @override
  Future<Result<void>> followUser(String userId) =>
      guard(() => _dataSource.followUser(userId));

  @override
  Future<Result<void>> unfollowUser(String userId) =>
      guard(() => _dataSource.unfollowUser(userId));

  @override
  Future<Result<CursorPage<FollowUser>>> getFollowers({
    required String userId,
    required int limit,
    String? cursor,
  }) => guard(
    () async => _toPage(
      await _dataSource.getFollowers(
        userId: userId,
        limit: limit + 1,
        cursor: FollowCursor.decode(cursor),
      ),
      limit,
    ),
  );

  @override
  Future<Result<CursorPage<FollowUser>>> getFollowings({
    required String userId,
    required int limit,
    String? cursor,
  }) => guard(
    () async => _toPage(
      await _dataSource.getFollowings(
        userId: userId,
        limit: limit + 1,
        cursor: FollowCursor.decode(cursor),
      ),
      limit,
    ),
  );

  /// 한 개를 더 받아 다음 페이지 존재 여부를 판정한다. COUNT 를 매번 돌리지
  /// 않기 위해서이고, 피드가 이미 쓰는 방식이다.
  CursorPage<FollowUser> _toPage(List<FollowUserDto> rows, int limit) {
    final hasMore = rows.length > limit;
    final page = hasMore ? rows.take(limit).toList() : rows;

    return CursorPage<FollowUser>(
      items: page.map((dto) => dto.toEntity()).toList(),
      nextCursor: hasMore
          ? FollowCursor(
              createdAt: page.last.createdAt,
              id: page.last.id,
            ).encode()
          : null,
    );
  }
}
