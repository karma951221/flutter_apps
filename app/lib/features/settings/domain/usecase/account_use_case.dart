import 'package:injectable/injectable.dart';

import '../../../../core/result/result.dart';
import '../entity/account_content_summary.dart';
import '../repository/account_repository.dart';
import 'scenario/get_my_content_summary_scenario.dart';

/// settings feature 의 presentation 진입점 (계정 단위 조회).
///
/// 탈퇴 실행 자체는 세션을 없애는 일이라 `AuthUseCase.deleteAccount` 에 남아
/// 있다. 여기는 그 앞에서 보여줄 것을 읽는다.
abstract interface class AccountUseCase {
  Future<Result<AccountContentSummary>> myContentSummary();
}

@LazySingleton(as: AccountUseCase)
class DefaultAccountUseCase implements AccountUseCase {
  DefaultAccountUseCase(this._repository);

  final AccountRepository _repository;

  @override
  Future<Result<AccountContentSummary>> myContentSummary() =>
      GetMyContentSummaryScenario(_repository)();
}
