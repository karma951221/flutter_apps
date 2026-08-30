import '../../../../../core/pagination/cursor_page.dart';
import '../../../../../core/result/result.dart';
import '../../entity/follow_user.dart';
import '../../repository/follow_repository.dart';
import 'follow_page_request.dart';

/// 팔로잉 목록 조회.
class GetFollowingsScenario {
  const GetFollowingsScenario(this._repository);

  final FollowRepository _repository;

  Future<Result<CursorPage<FollowUser>>> call({
    required String userId,
    required int limit,
    String? cursor,
  }) {
    final invalid = FollowPageRequest.validate(
      userId: userId,
      limit: limit,
      cursor: cursor,
    );
    if (invalid != null) return Future.value(invalid);

    return _repository.getFollowings(
      userId: userId,
      limit: limit,
      cursor: cursor,
    );
  }
}
