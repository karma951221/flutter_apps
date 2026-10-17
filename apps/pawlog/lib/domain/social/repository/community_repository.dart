import 'package:core/core.dart';

import '../entity/walk_post.dart';
import '../entity/walk_post_draft.dart';

/// 모두의 산책 — 공유 산책 목록 · 공유 · 좋아요(plan W5 social).
abstract interface class CommunityRepository {
  /// 최신순(`created_at desc, id desc`) 한 페이지. [after] 는 앞 페이지의
  /// [CursorPage.nextCursor] 를 그대로 넘긴다(불투명 문자열). 로그인 없이 된다.
  Future<Result<CursorPage<WalkPost>>> fetchPage({
    String? after,
    int limit = 20,
  });

  /// 공유하고 글 id 를 돌려준다. 같은 산책을 다시 공유하면 그 글을 갱신해 맨 위로 올린다.
  Future<Result<String>> publish(WalkPostDraft draft);

  /// 공유 중인 글의 반려견 · 메모 · 경로를 [draft] 로 고친다. 목록 위치(`created_at`)는 그대로.
  /// 고친 글이 있으면 true, 공유하지 않았거나 공유 취소한 산책이면 false(되살리지 않는다).
  Future<Result<bool>> updatePublished(WalkPostDraft draft);

  /// 공유 취소. 공유한 적 없는 산책이어도 Ok.
  Future<Result<void>> unpublish(String localWalkId);

  /// 지금 사용자가 이 산책을 공유 중인지. 로그인하지 않았으면 false.
  Future<Result<bool>> isPublished(String localWalkId);

  /// 이미 눌렀어도 Ok.
  Future<Result<void>> like(String postId);

  /// 누른 적 없어도 Ok.
  Future<Result<void>> unlike(String postId);
}
