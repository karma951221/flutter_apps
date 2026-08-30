import '../../domain/entity/report_reason.dart';
import '../../domain/entity/report_target.dart';

abstract interface class ReportDataSource {
  Future<void> submitReport(
    ReportTarget target, {
    required ReportReason reason,
    String? detail,
  });
}
