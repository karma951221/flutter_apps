import '../../../../core/pagination/cursor_page.dart';
import '../../../../core/result/result.dart';
import '../entity/feed_post.dart';

/// 피드 목록 저장소.
///
/// 게시물의 작성·수정·삭제는 post feature 가 소유한다. 여기서는 조회만 한다.
abstract interface class FeedRepository {
  /// 최신순 피드 한 페이지를 조회한다. [cursor] 가 null 이면 첫 페이지다.
  ///
  /// 항목마다 작성자 정보가 함께 온다. 목록을 받은 뒤 작성자를 따로 조회하는
  /// 경로는 두지 않는다 (N+1 방지 — 기획 F4).
  Future<Result<CursorPage<FeedPost>>> getPosts({
    required int limit,
    String? cursor,
    String? authorId,
  });
}
