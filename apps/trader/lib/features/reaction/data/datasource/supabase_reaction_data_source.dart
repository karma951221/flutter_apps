import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_code.dart';
import '../../domain/entity/reaction_target.dart';
import '../../domain/entity/reaction_type.dart';
import 'reaction_data_source.dart';

@LazySingleton(as: ReactionDataSource)
class SupabaseReactionDataSource implements ReactionDataSource {
  SupabaseReactionDataSource(this._client);

  final SupabaseClient _client;

  /// 대상 → 테이블·컬럼 매핑이 있는 **유일한 곳**.
  ///
  /// 반응 대상이 늘어나면 여기 한 줄과 ReactionTarget 의 변형, 그리고
  /// 마이그레이션만 는다. domain 과 presentation 은 그대로다.
  static ({String table, String column, String id}) _mapping(
    ReactionTarget target,
  ) => switch (target) {
    ReactionPostTarget(:final id) => (
      table: 'post_reactions',
      column: 'post_id',
      id: id,
    ),
    ReactionCommentTarget(:final id) => (
      table: 'comment_reactions',
      column: 'comment_id',
      id: id,
    ),
  };

  @override
  Future<void> setReaction(ReactionTarget target, ReactionType type) async {
    if (_client.auth.currentUser == null) {
      throw const Failure.auth(
        message: '로그인이 필요합니다',
        failureCode: FailureCode.authenticationRequired,
      );
    }

    final mapping = _mapping(target);

    // 좋아요 ↔ 싫어요 전환은 upsert 한 번이다. 삭제 후 삽입이면 왕복이 둘이고
    // 중간 상태가 화면에 보인다. user_id 는 페이로드에 넣지 않는다 —
    // DB 의 default auth.uid() 가 채우므로 위조 경로가 없다. 충돌 대상에는
    // 이름으로만 지정한다.
    await _client.from(mapping.table).upsert({
      mapping.column: mapping.id,
      'type': type.code,
    }, onConflict: 'user_id,${mapping.column}');
  }

  @override
  Future<void> clearReaction(ReactionTarget target) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const Failure.auth(
        message: '로그인이 필요합니다',
        failureCode: FailureCode.authenticationRequired,
      );
    }

    final mapping = _mapping(target);

    // 취소는 행 삭제다. 반응에는 자식이 달리지 않으므로 소프트 삭제의 이유가
    // 없다. user_id 조건은 PK 를 좁히기 위한 것이고, 권한 경계는 삭제 정책이다.
    await _client
        .from(mapping.table)
        .delete()
        .eq(mapping.column, mapping.id)
        .eq('user_id', userId);
  }
}
