import 'package:injectable/injectable.dart';

import '../../../../core/result/result.dart';
import '../entity/blocked_user.dart';
import '../entity/report_reason.dart';
import '../entity/report_target.dart';
import '../repository/block_repository.dart';
import '../repository/report_repository.dart';
import 'scenario/block_user_scenario.dart';
import 'scenario/get_blocked_users_scenario.dart';
import 'scenario/is_blocked_by_me_scenario.dart';
import 'scenario/submit_report_scenario.dart';
import 'scenario/unblock_user_scenario.dart';

/// safety feature 의 presentation 진입점. 신고와 차단을 함께 연다.
abstract interface class SafetyUseCase {
  Future<Result<void>> submit(
    ReportTarget target, {
    required ReportReason reason,
    String? detail,
  });

  /// 사용자를 차단한다.
  Future<Result<void>> blockUser(String userId);

  /// 차단을 해제한다.
  Future<Result<void>> unblockUser(String userId);

  /// 내가 차단한 사용자 목록을 조회한다.
  Future<Result<List<BlockedUser>>> getBlockedUsers();

  /// 내가 이 사용자를 차단했는지 확인한다.
  Future<Result<bool>> isBlockedByMe(String userId);
}

@LazySingleton(as: SafetyUseCase)
class DefaultSafetyUseCase implements SafetyUseCase {
  DefaultSafetyUseCase(this._reportRepository, this._blockRepository);

  final ReportRepository _reportRepository;
  final BlockRepository _blockRepository;

  @override
  Future<Result<void>> submit(
    ReportTarget target, {
    required ReportReason reason,
    String? detail,
  }) => SubmitReportScenario(
    _reportRepository,
  )(target, reason: reason, detail: detail);

  @override
  Future<Result<void>> blockUser(String userId) =>
      BlockUserScenario(_blockRepository)(userId);

  @override
  Future<Result<void>> unblockUser(String userId) =>
      UnblockUserScenario(_blockRepository)(userId);

  @override
  Future<Result<List<BlockedUser>>> getBlockedUsers() =>
      GetBlockedUsersScenario(_blockRepository)();

  @override
  Future<Result<bool>> isBlockedByMe(String userId) =>
      IsBlockedByMeScenario(_blockRepository)(userId);
}
