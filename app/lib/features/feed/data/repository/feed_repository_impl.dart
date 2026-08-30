import 'package:injectable/injectable.dart';

import '../../../../core/data/repository/repository_error_handler.dart';
import '../../../../core/pagination/cursor_page.dart';
import '../../../../core/result/result.dart';
import '../../domain/entity/feed_post.dart';
import '../../domain/entity/feed_source.dart';
import '../../domain/repository/feed_repository.dart';
import '../cursor/feed_cursor.dart';
import '../datasource/feed_data_source.dart';
import '../mapper/feed_post_mapper.dart';

/// FeedDataSource 를 domain Repository 계약으로 변환하는 구현체.
@LazySingleton(as: FeedRepository)
class FeedRepositoryImpl with RepositoryErrorHandler implements FeedRepository {
  FeedRepositoryImpl(this._dataSource);

  final FeedDataSource _dataSource;

  @override
  Future<Result<CursorPage<FeedPost>>> getPosts({
    required int limit,
    String? cursor,
    String? authorId,
    FeedSource source = FeedSource.all,
  }) => guard(() async {
    // 한 개를 더 요청해서 다음 페이지 존재 여부를 알아낸다. 전체 개수를 세는
    // COUNT 쿼리를 매번 돌리지 않아도 된다.
    final rows = await _dataSource.getPosts(
      limit: limit + 1,
      cursor: FeedCursor.decode(cursor),
      authorId: authorId,
      source: source,
    );

    final hasMore = rows.length > limit;
    final page = hasMore ? rows.take(limit).toList() : rows;

    return CursorPage<FeedPost>(
      items: page.map((dto) => dto.toEntity()).toList(),
      nextCursor: hasMore ? page.last.toCursor().encode() : null,
    );
  });
}
