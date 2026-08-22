import '../../../../core/pagination/cursor_page.dart';
import '../../../../core/result/result.dart';
import '../../../post/domain/entity/post.dart';

/// 피드 목록 저장소.
///
/// 게시물의 작성·수정·삭제는 post feature 가 소유한다. 여기서는 조회만 한다.
abstract interface class FeedRepository {
  /// 최신순 피드 한 페이지를 조회한다. [cursor] 가 null 이면 첫 페이지다.
  Future<Result<CursorPage<Post>>> getPosts({
    required int limit,
    String? cursor,
  });
}
