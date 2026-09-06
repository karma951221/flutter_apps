import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_data_source.dart';

@LazySingleton(as: AccountDataSource)
class SupabaseAccountDataSource implements AccountDataSource {
  SupabaseAccountDataSource(this._client);

  final SupabaseClient _client;

  /// HEAD 요청 두 번. 행을 받지 않고 `Content-Range` 의 개수만 읽는다.
  /// 소프트 삭제된 행은 RLS 가 이미 숨기지만, 정책이 바뀌어도 개수가 흔들리지
  /// 않도록 `deleted_at is null` 을 명시한다.
  @override
  Future<({int postCount, int commentCount})?> myContentSummary() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final postCount = await _client
        .from('posts')
        .count(CountOption.exact)
        .eq('author_id', userId)
        .isFilter('deleted_at', null);
    final commentCount = await _client
        .from('post_comments')
        .count(CountOption.exact)
        .eq('author_id', userId)
        .isFilter('deleted_at', null);
    return (postCount: postCount, commentCount: commentCount);
  }
}
