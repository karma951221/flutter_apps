import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../dto/blocked_user_dto.dart';
import 'block_data_source.dart';

@LazySingleton(as: BlockDataSource)
class SupabaseBlockDataSource implements BlockDataSource {
  SupabaseBlockDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<void> blockUser(String userId) async {
    if (_client.auth.currentUser == null) {
      throw const Failure.auth(message: '로그인이 필요합니다');
    }

    // blocker_id 는 보내지 않는다. GRANT 에 없어서 보내면 42501 로 막히고,
    // DB 의 default auth.uid() 가 채우므로 위조 경로가 없다.
    await _client.from('blocks').insert({'blocked_id': userId});
  }

  @override
  Future<void> unblockUser(String userId) async {
    // blocker_id 조건은 걸지 않는다 — blocks_delete_own 정책이 내가 건 차단만
    // 지우도록 이미 좁혀 준다.
    await _client.from('blocks').delete().eq('blocked_id', userId);
  }

  @override
  Future<List<BlockedUserDto>> getBlockedUsers() async {
    final rows = await _client
        .from('blocked_users')
        .select('id, nickname, avatar_url, created_at')
        .order('created_at', ascending: false);
    return rows.map(BlockedUserDto.fromJson).toList();
  }

  @override
  Future<bool> isBlocked(String userId) async {
    // is_blocked_with() 는 쓰지 않는다 — 그 함수는 양방향이라 상대가 나를
    // 차단한 경우에도 true 를 돌려준다. 여기서 필요한 것은 "내가 건" 차단
    // 여부뿐이라 blocks 를 직접 읽고, RLS(blocks_select_own)가 내 행으로
    // 좁혀 준다.
    final row = await _client
        .from('blocks')
        .select('blocked_id')
        .eq('blocked_id', userId)
        .maybeSingle();
    return row != null;
  }
}
