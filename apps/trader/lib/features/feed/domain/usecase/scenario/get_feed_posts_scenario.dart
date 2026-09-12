import '../../../../../core/error/failure.dart';
import '../../../../../core/error/failure_code.dart';
import '../../../../../core/pagination/cursor_page.dart';
import '../../../../../core/result/result.dart';
import '../../entity/feed_post.dart';
import '../../entity/feed_source.dart';
import '../../repository/feed_repository.dart';

class GetFeedPostsScenario {
  const GetFeedPostsScenario(this._repository);

  /// 한 번에 가져올 수 있는 최대 개수. 이보다 크면 요청 자체를 막는다.
  static const maxPageSize = 50;

  final FeedRepository _repository;

  Future<Result<CursorPage<FeedPost>>> call({
    required int limit,
    String? cursor,
    String? authorId,
    FeedSource source = FeedSource.all,
  }) {
    if (limit < 1 || limit > maxPageSize) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '올바른 피드 조회 범위가 아닙니다',
            failureCode: FailureCode.feedRangeInvalid,
          ),
        ),
      );
    }
    if (cursor != null && cursor.trim().isEmpty) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '잘못된 피드 커서입니다',
            field: 'cursor',
            failureCode: FailureCode.feedCursorInvalid,
          ),
        ),
      );
    }
    return _repository.getPosts(
      limit: limit,
      cursor: cursor,
      authorId: authorId,
      source: source,
    );
  }
}
