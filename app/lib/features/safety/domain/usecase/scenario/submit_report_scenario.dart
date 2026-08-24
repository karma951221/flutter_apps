import '../../../../../core/result/result.dart';
import '../../entity/report_reason.dart';
import '../../entity/report_target.dart';
import '../../report_policy.dart';
import '../../repository/report_repository.dart';

/// 신고 접수.
///
/// 상세 설명 정규화가 여기 있는 이유: 빈 값을 null 로 바꾸는 것은 화면의 사정이
/// 아니라 저장 규칙이다. 어느 화면에서 신고하든 같은 값이 저장돼야 한다.
class SubmitReportScenario {
  const SubmitReportScenario(this._repository);

  final ReportRepository _repository;

  Future<Result<void>> call(
    ReportTarget target, {
    required ReportReason reason,
    String? detail,
  }) => _repository.submitReport(
    target,
    reason: reason,
    detail: ReportPolicy.normalizeDetail(detail),
  );
}
