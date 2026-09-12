import 'package:core/core.dart';
import '../entity/blocked_user.dart';

/// 차단 저장소.
///
/// `reports` 와는 다른 테이블 관심사다 — 신고를 쓰지 않는 화면이 차단 코드까지
/// 끌고 오지 않도록 `ReportRepository` 와 합치지 않는다.
abstract interface class BlockRepository {
  /// 사용자를 차단한다. 자기 차단·중복 차단은 서버가 거부한다.
  Future<Result<void>> blockUser(String userId);

  /// 차단을 해제한다.
  Future<Result<void>> unblockUser(String userId);

  /// 내가 차단한 사용자 목록을 최근 차단 순으로 돌려준다.
  Future<Result<List<BlockedUser>>> getBlockedUsers();

  /// 내가 이 사용자를 차단했는지 여부.
  ///
  /// 양방향 판정(상대가 나를 차단했는가)이 아니다 — 프로필 메뉴가 '차단'과
  /// '차단 해제' 중 무엇을 그릴지만 정하면 되므로 내가 건 차단만 본다.
  Future<Result<bool>> isBlockedByMe(String userId);
}
