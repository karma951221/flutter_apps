import '../../../../../core/error/failure.dart';
import '../../../../../core/error/failure_code.dart';
import '../../../../../core/pagination/cursor_page.dart';
import '../../../../../core/result/result.dart';
import '../../entity/follow_user.dart';

/// 팔로워 · 팔로잉 목록 요청의 공통 검증.
///
/// 두 시나리오는 방향만 다르고 요청 모양이 같다. 검증을 각자 들면 한쪽만
/// 고쳐지는 자리가 된다 — 2026-08-27 리뷰가 걷어낸 중복과 같은 종류다.
abstract final class FollowPageRequest {
  /// 한 번에 가져올 수 있는 최대 개수. 피드와 같은 상한을 쓴다.
  static const maxPageSize = 50;

  /// 문제가 없으면 null, 있으면 그대로 돌려줄 [Err] 를 준다.
  static Err<CursorPage<FollowUser>>? validate({
    required String userId,
    required int limit,
    String? cursor,
  }) {
    if (userId.trim().isEmpty) {
      return const Err(
        Failure.validation(
          message: '사용자 식별자가 필요합니다',
          failureCode: FailureCode.followUserIdRequired,
        ),
      );
    }
    if (limit < 1 || limit > maxPageSize) {
      return const Err(
        Failure.validation(
          message: '올바른 팔로우 조회 범위가 아닙니다',
          failureCode: FailureCode.followRangeInvalid,
        ),
      );
    }
    if (cursor != null && cursor.trim().isEmpty) {
      return const Err(
        Failure.validation(
          message: '잘못된 팔로우 커서입니다',
          field: 'cursor',
          failureCode: FailureCode.followCursorInvalid,
        ),
      );
    }
    return null;
  }
}
