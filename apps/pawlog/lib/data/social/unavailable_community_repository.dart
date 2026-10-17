import 'package:core/core.dart';

import '../../domain/social/entity/walk_post.dart';
import '../../domain/social/entity/walk_post_draft.dart';
import '../../domain/social/repository/community_repository.dart';

/// Supabase 초기화가 실패했을 때의 [CommunityRepository]. 모든 요청이 네트워크 실패다 —
/// 모두의 산책은 오류 안내를 보이고, 로컬 기능은 그대로 쓴다(plan 결정 8).
class UnavailableCommunityRepository implements CommunityRepository {
  const UnavailableCommunityRepository();

  static const _failure = Failure.network(
    failureCode: FailureCode.networkUnavailable,
  );

  @override
  Future<Result<CursorPage<WalkPost>>> fetchPage({
    String? after,
    int limit = 20,
  }) async => const Err(_failure);

  @override
  Future<Result<String>> publish(WalkPostDraft draft) async =>
      const Err(_failure);

  @override
  Future<Result<bool>> updatePublished(WalkPostDraft draft) async =>
      const Err(_failure);

  @override
  Future<Result<void>> unpublish(String localWalkId) async =>
      const Err(_failure);

  @override
  Future<Result<bool>> isPublished(String localWalkId) async =>
      const Err(_failure);

  @override
  Future<Result<void>> like(String postId) async => const Err(_failure);

  @override
  Future<Result<void>> unlike(String postId) async => const Err(_failure);
}
