import 'package:core/core.dart';

import '../../core/supabase/supabase_initializer.dart';

import '../../domain/social/entity/walk_post.dart';
import '../../domain/social/entity/walk_post_draft.dart';
import '../../domain/social/repository/community_repository.dart';
import '../../domain/walk/entity/geo_point.dart';
import 'supabase_community_gateway.dart';
import 'walk_post_cursor.dart';

/// [CommunityRepository] 의 Supabase 구현. 오류는 core `RepositoryErrorHandler` 로 바꾼다.
///
/// 결과를 바꾸지 않는 실패는 Ok 로 삼킨다: 이미 누른 좋아요(23505 → duplicateValue),
/// 없는 좋아요 지우기(지울 행 0), 공유한 적 없는 산책의 공유 취소(RPC false).
/// 화면은 "그 상태가 되었는가" 만 알면 된다.
///
/// 서버 호출은 하나하나 [deadline](기본 [socialCallDeadline]) 안에 끝낸다. 요청마다 걸린
/// 시간 제한(`TimeoutHttpClient`)만으로는 SDK 가 요청 앞에 붙이는 세션 갱신(같은 제한)까지
/// 더해져 약 20초가 된다. 넘으면 `TimeoutException` → 네트워크 실패다.
///
/// 등록은 `RegisterModule` 이 Supabase 초기화 결과를 보고 한다.
class SupabaseCommunityRepository
    with RepositoryErrorHandler
    implements CommunityRepository {
  SupabaseCommunityRepository(
    this._gateway, {
    this.deadline = socialCallDeadline,
  });

  final SupabaseCommunityGateway _gateway;
  final Duration deadline;

  /// [call] 을 [deadline] 안에 끝내고 오류를 바꾼다.
  Future<Result<T>> _guarded<T>(Future<T> Function() call) =>
      guard(() => call().timeout(deadline));

  static const _signInRequired = Failure.auth(
    message: '로그인이 필요합니다',
    code: 'sign_in_required',
    failureCode: FailureCode.authenticationRequired,
  );

  @override
  Future<Result<CursorPage<WalkPost>>> fetchPage({
    String? after,
    int limit = 20,
  }) => _guarded(() async {
    // limit + 1 을 읽어 다음 페이지가 있는지 본다(COUNT 없이).
    final rows = await _gateway.fetchPosts(
      limit: limit + 1,
      before: WalkPostCursor.decode(after),
    );
    final hasMore = rows.length > limit;
    final items = (hasMore ? rows.sublist(0, limit) : rows)
        .map(_toPost)
        .toList();
    // 다음 커서는 실제로 돌려주는 마지막 글로 만든다 — 잘라 낸 글로 만들면 한 건이 빠진다.
    final last = items.isEmpty ? null : items.last;
    return CursorPage(
      items: items,
      nextCursor: hasMore && last != null
          ? WalkPostCursor(createdAt: last.createdAt, id: last.id).encode()
          : null,
    );
  });

  @override
  Future<Result<String>> publish(WalkPostDraft draft) =>
      _guarded(() => _gateway.publish(_paramsOf(draft)));

  @override
  Future<Result<bool>> updatePublished(WalkPostDraft draft) => _guarded(
    () => _gateway.update({
      'p_local_walk_id': draft.localWalkId,
      'p_dog_names': draft.dogNames,
      'p_memo': draft.memo,
      'p_route_preview': _routeParamOf(draft),
    }),
  );

  @override
  Future<Result<void>> unpublish(String localWalkId) =>
      _guarded(() => _gateway.unpublish(localWalkId));

  @override
  Future<Result<bool>> isPublished(String localWalkId) => _guarded(() async {
    final userId = _gateway.currentUserId;
    if (userId == null) return false;
    return _gateway.hasLivePost(authorId: userId, localWalkId: localWalkId);
  });

  @override
  Future<Result<void>> like(String postId) async {
    if (_gateway.currentUserId == null) return const Err(_signInRequired);
    final result = await _guarded(() => _gateway.insertLike(postId));
    return switch (result) {
      Err(failure: Failure(failureCode: FailureCode.duplicateValue)) =>
        const Ok(null),
      _ => result,
    };
  }

  @override
  Future<Result<void>> unlike(String postId) async {
    final userId = _gateway.currentUserId;
    if (userId == null) return const Err(_signInRequired);
    return _guarded(() => _gateway.deleteLike(postId: postId, userId: userId));
  }

  static Map<String, dynamic> _paramsOf(WalkPostDraft draft) => {
    'p_local_walk_id': draft.localWalkId,
    'p_started_at': draft.startedAt.toUtc().toIso8601String(),
    'p_duration_seconds': draft.duration.inSeconds,
    'p_distance_meters': draft.distanceMeters,
    'p_dog_names': draft.dogNames,
    'p_memo': draft.memo,
    'p_route_preview': _routeParamOf(draft),
  };

  /// 남은 경로가 없으면 경로 없이 공유한다(plan 결정 4).
  static List<Map<String, double>>? _routeParamOf(WalkPostDraft draft) =>
      draft.routePreview.isEmpty
      ? null
      : [
          for (final p in draft.routePreview) {'lat': p.lat, 'lng': p.lng},
        ];

  static WalkPost _toPost(Map<String, dynamic> row) => WalkPost(
    id: row['id'] as String,
    authorId: row['author_id'] as String,
    authorNickname: row['author_nickname'] as String? ?? '',
    authorAvatarUrl: row['author_avatar_url'] as String?,
    localWalkId: row['local_walk_id'] as String,
    startedAt: DateTime.parse(row['started_at'] as String).toLocal(),
    duration: Duration(seconds: (row['duration_seconds'] as num).toInt()),
    distanceMeters: (row['distance_meters'] as num).toDouble(),
    dogNames: [for (final name in row['dog_names'] as List) name as String],
    memo: row['memo'] as String?,
    routePreview: _routeOf(row['route_preview']),
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    likeCount: (row['like_count'] as num).toInt(),
    likedByMe: row['liked_by_me'] as bool? ?? false,
  );

  /// 깨진 경로는 빈 목록 — 한 행 때문에 목록 전체가 실패하면 안 된다(`RoutePreview.decode` 와 같은 판단).
  static List<GeoPoint> _routeOf(Object? raw) {
    if (raw is! List) return const [];
    final points = <GeoPoint>[];
    for (final e in raw) {
      if (e case {'lat': final num lat, 'lng': final num lng}) {
        points.add(GeoPoint(lat: lat.toDouble(), lng: lng.toDouble()));
      } else {
        return const [];
      }
    }
    return points;
  }
}
