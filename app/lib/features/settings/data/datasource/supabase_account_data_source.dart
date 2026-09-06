import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_data_source.dart';

@LazySingleton(as: AccountDataSource)
class SupabaseAccountDataSource implements AccountDataSource {
  SupabaseAccountDataSource(this._client);

  final SupabaseClient _client;

  /// 댓글은 `post_comments` 가 아니라 이 뷰로 센다. 테이블 쪽 SELECT GRANT 는
  /// 컬럼 목록(`content` 제외)이라 `select` 파라미터 없는 count HEAD 요청이
  /// `select=*` 로 평가돼 42501 로 거부된다 — docs/schema.md §8 GRANT 참고.
  /// 뷰는 `grant select ... to anon, authenticated` 전체라 그대로 통과한다.
  static const _commentSource = 'post_comments_visible';

  /// HEAD 요청 두 번. 행을 받지 않고 `Content-Range` 의 개수만 읽는다.
  /// 두 요청은 서로를 기다릴 이유가 없어 함께 던진다 — 탭과 다이얼로그 사이의
  /// 대기가 왕복 하나로 줄어든다.
  ///
  /// 소프트 삭제된 행은 RLS·뷰가 이미 숨기지만, 정책이 바뀌어도 개수가 흔들리지
  /// 않도록 `deleted_at is null` 을 명시한다.
  @override
  Future<({int postCount, int commentCount})?> myContentSummary() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final [postCount, commentCount] = await Future.wait([
      _client
          .from('posts')
          .count(CountOption.exact)
          .eq('author_id', userId)
          .isFilter('deleted_at', null),
      _client
          .from(_commentSource)
          .count(CountOption.exact)
          .eq('author_id', userId)
          .isFilter('deleted_at', null),
    ]);
    return (postCount: postCount, commentCount: commentCount);
  }
}
