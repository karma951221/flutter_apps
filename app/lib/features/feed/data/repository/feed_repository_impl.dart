import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../../domain/entity/feed_post.dart';
import '../../domain/entity/feed_post_draft.dart';
import '../../domain/entity/feed_post_update.dart';
import '../../domain/repository/feed_repository.dart';
import '../datasource/feed_data_source.dart';
import '../mapper/feed_post_mapper.dart';
import 'feed_repository_error_handler.dart';

/// FeedDataSource를 domain Repository 계약으로 변환하는 구현체.
@LazySingleton(as: FeedRepository)
class FeedRepositoryImpl
    with FeedRepositoryErrorHandler
    implements FeedRepository {
  FeedRepositoryImpl(this._dataSource);

  final FeedDataSource _dataSource;

  @override
  Future<Result<List<FeedPost>>> getFeedPosts({
    required int limit,
    required int offset,
  }) => guard(() async {
    return (await _dataSource.getFeedPosts(
      limit: limit,
      offset: offset,
    )).map((post) => post.toEntity()).toList();
  });

  @override
  Future<Result<FeedPost>> getFeedPost(String postId) => guard(() async {
    return (await _dataSource.getFeedPost(postId)).toEntity();
  });

  @override
  Future<Result<FeedPost>> createFeedPost(FeedPostDraft draft) {
    return guard(() async {
      final post = await _dataSource.createFeedPost(draft);
      return post?.toEntity() ?? _throwNotAuthenticated();
    });
  }

  @override
  Future<Result<FeedPost>> updateFeedPost(
    String postId,
    FeedPostUpdate update,
  ) {
    return guard(() async {
      final post = await _dataSource.updateFeedPost(postId, update);
      return post?.toEntity() ?? _throwNotAuthenticated();
    });
  }

  @override
  Future<Result<void>> deleteFeedPost(String postId) {
    return guard(() async {
      final deleted = await _dataSource.deleteFeedPost(postId);
      if (deleted == null) _throwNotAuthenticated();
    });
  }

  Never _throwNotAuthenticated() => throw const Failure.auth(
    message: '로그인이 필요합니다',
    code: 'not_authenticated',
  );
}
