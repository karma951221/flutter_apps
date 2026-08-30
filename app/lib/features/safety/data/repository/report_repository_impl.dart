import 'package:injectable/injectable.dart';

import '../../../../core/data/repository/repository_error_handler.dart';
import '../../../../core/result/result.dart';
import '../../domain/entity/report_reason.dart';
import '../../domain/entity/report_target.dart';
import '../../domain/repository/report_repository.dart';
import '../datasource/report_data_source.dart';

@LazySingleton(as: ReportRepository)
class ReportRepositoryImpl
    with RepositoryErrorHandler
    implements ReportRepository {
  ReportRepositoryImpl(this._dataSource);

  final ReportDataSource _dataSource;

  @override
  Future<Result<void>> submitReport(
    ReportTarget target, {
    required ReportReason reason,
    String? detail,
  }) => guard(
    () => _dataSource.submitReport(target, reason: reason, detail: detail),
  );
}
