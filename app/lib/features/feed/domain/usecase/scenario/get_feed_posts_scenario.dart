import '../../../../../core/error/failure.dart';
import '../../../../../core/pagination/cursor_page.dart';
import '../../../../../core/result/result.dart';
import '../../../../post/domain/entity/post.dart';
import '../../repository/feed_repository.dart';

class GetFeedPostsScenario {
  const GetFeedPostsScenario(this._repository);

  /// 한 번에 가져올 수 있는 최대 개수. 이보다 크면 요청 자체를 막는다.
  static const maxPageSize = 50;

  final FeedRepository _repository;

  Future<Result<CursorPage<Post>>> call({
    required int limit,
    String? cursor,
  }) {
    if (limit < 1 || limit > maxPageSize) {
      return Future.value(
        const Err(Failure.validation(message: '올바른 피드 조회 범위가 아닙니다')),
      );
    }
    if (cursor != null && cursor.trim().isEmpty) {
      return Future.value(
        const Err(
          Failure.validation(message: '잘못된 피드 커서입니다', field: 'cursor'),
        ),
      );
    }
    return _repository.getPosts(limit: limit, cursor: cursor);
  }
}
