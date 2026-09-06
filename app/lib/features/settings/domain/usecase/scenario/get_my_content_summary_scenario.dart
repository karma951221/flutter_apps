import '../../../../../core/result/result.dart';
import '../../entity/account_content_summary.dart';
import '../../repository/account_repository.dart';

class GetMyContentSummaryScenario {
  const GetMyContentSummaryScenario(this._repository);

  final AccountRepository _repository;

  Future<Result<AccountContentSummary>> call() =>
      _repository.myContentSummary();
}
