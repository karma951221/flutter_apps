import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_code.dart';
import '../cursor/follow_cursor.dart';
import '../dto/follow_user_dto.dart';
import 'follow_data_source.dart';

@LazySingleton(as: FollowDataSource)
class SupabaseFollowDataSource implements FollowDataSource {
  SupabaseFollowDataSource(this._client);

  final SupabaseClient _client;

  /// 방향마다 뷰가 다르다. 컬럼은 같다 — 어느 쪽이 "상대"인지만 뷰가 정한다.
  static const _followersView = 'user_followers';
  static const _followingsView = 'user_followings';

  static const _columns = 'id, nickname, avatar_url, created_at';

  @override
  Future<void> followUser(String userId) async {
    _requireSignedIn();

    // follower_id 는 보내지 않는다. GRANT 에 없어서 보내면 42501 로 막히고,
    // DB 의 default auth.uid() 가 채우므로 위조 경로가 없다 — 차단·신고와
    // 같은 규칙이다.
    try {
      await _client.from('follows').insert({'followee_id': userId});
    } on PostgrestException catch (error) {
      // 여기서 오는 42501 은 사실상 하나뿐이다 — follows_insert_own 의
      // 차단 검사. follower_id 는 애초에 보내지 않으므로 위조로 막힐 일이
      // 없다. 공용 mapper 는 42501 을 일반 권한 오류로 옮기므로, 이 자리에서만
      // 코드를 붙인다.
      //
      // 문구는 방향을 밝히지 않는다. is_blocked_with() 가 양방향이라 거부를
      // 보는 쪽이 차단을 건 쪽이라고 가정할 수 없다
      // (docs/features/safety/plan-block.md 의 일반화된 규칙).
      if (error.code == '42501') {
        throw Failure.forbidden(
          message: error.message,
          failureCode: FailureCode.followBlocked,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> unfollowUser(String userId) async {
    _requireSignedIn();

    // follower_id 조건은 걸지 않는다 — follows_delete_own 정책이 내가 건
    // 팔로우만 지우도록 이미 좁혀 준다.
    //
    // unblockUser() 와 달리 .select().single() 을 붙이지 않는다. 거기서는
    // 0행 삭제가 곧 "차단한 적이 없는 대상"이라 notFound 로 올릴 수 있다 —
    // blocks 행은 내가 지우지 않는 한 사라지지 않기 때문이다. follows 행은
    // 다르다. blocks_drop_follows 트리거가 상대의 차단만으로도 내 행을
    // 지우고, 다른 기기에서 이미 해제했을 수도 있다. 즉 화면에 '팔로잉'이
    // 떠 있어도 행은 이미 없을 수 있다. 그때 notFound 를 올리면
    // FollowActionCubit 이 눌리기 전 값(=팔로잉)으로 되돌려, 팔로우하지 않은
    // 상태인데 버튼만 '팔로잉'으로 남는다. 해제는 멱등이어야 한다 — 0행
    // 삭제도 "이제 팔로우하지 않는다"는 같은 결과다.
    await _client.from('follows').delete().eq('followee_id', userId);
  }

  @override
  Future<List<FollowUserDto>> getFollowers({
    required String userId,
    required int limit,
    FollowCursor? cursor,
  }) =>
      _page(view: _followersView, userId: userId, limit: limit, cursor: cursor);

  @override
  Future<List<FollowUserDto>> getFollowings({
    required String userId,
    required int limit,
    FollowCursor? cursor,
  }) => _page(
    view: _followingsView,
    userId: userId,
    limit: limit,
    cursor: cursor,
  );

  /// 두 방향의 조회는 뷰 이름만 다르다.
  Future<List<FollowUserDto>> _page({
    required String view,
    required String userId,
    required int limit,
    FollowCursor? cursor,
  }) async {
    // 차단 필터를 여기에 쓰지 않는다. 뷰 정의가 is_blocked_with() 로 이미
    // 가린다 (docs/features/follow/plan.md).
    var query = _client.from(view).select(_columns).eq('user_id', userId);

    if (cursor != null) {
      final createdAt = cursor.createdAt.toUtc().toIso8601String();
      // (created_at, id) 사전식 비교. 같은 시각에 두 사람이 팔로우해도
      // 순서가 정해지고 경계에서 중복·누락이 생기지 않는다.
      query = query.or(
        'created_at.lt.$createdAt,'
        'and(created_at.eq.$createdAt,id.lt.${cursor.id})',
      );
    }

    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);

    return rows.map(FollowUserDto.fromJson).toList();
  }

  void _requireSignedIn() {
    if (_client.auth.currentUser == null) {
      throw const Failure.auth(
        message: '로그인이 필요합니다',
        failureCode: FailureCode.authenticationRequired,
      );
    }
  }
}
