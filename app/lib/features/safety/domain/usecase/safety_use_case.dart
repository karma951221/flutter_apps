import 'package:injectable/injectable.dart';

import '../../../../core/result/result.dart';
import '../entity/report_reason.dart';
import '../entity/report_target.dart';
import '../repository/report_repository.dart';
import 'scenario/submit_report_scenario.dart';

/// safety feature 의 presentation 진입점.
abstract interface class SafetyUseCase {
  Future<Result<void>> submit(
    ReportTarget target, {
    required ReportReason reason,
    String? detail,
  });
}

@LazySingleton(as: SafetyUseCase)
class DefaultSafetyUseCase implements SafetyUseCase {
  DefaultSafetyUseCase(this._repository);

  final ReportRepository _repository;

  @override
  Future<Result<void>> submit(
    ReportTarget target, {
    required ReportReason reason,
    String? detail,
  }) =>
      SubmitReportScenario(_repository)(target, reason: reason, detail: detail);
}
