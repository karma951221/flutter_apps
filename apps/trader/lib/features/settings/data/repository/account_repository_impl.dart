import 'package:injectable/injectable.dart';

import 'package:core/core.dart';
import '../../domain/entity/account_content_summary.dart';
import '../../domain/repository/account_repository.dart';
import '../datasource/account_data_source.dart';

@LazySingleton(as: AccountRepository)
class AccountRepositoryImpl
    with RepositoryErrorHandler
    implements AccountRepository {
  AccountRepositoryImpl(this._dataSource);

  final AccountDataSource _dataSource;

  @override
  Future<Result<AccountContentSummary>> myContentSummary() => guard(() async {
    final summary = await _dataSource.myContentSummary();
    if (summary == null) {
      throw const Failure.auth(
        message: '로그인이 필요합니다',
        code: 'not_authenticated',
        failureCode: FailureCode.authenticationRequired,
      );
    }
    return AccountContentSummary(
      postCount: summary.postCount,
      commentCount: summary.commentCount,
    );
  });
}
