import 'package:core/core.dart';
import 'package:feature_settings/feature_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAccountDataSource extends Mock implements AccountDataSource {}

void main() {
  late _MockAccountDataSource dataSource;
  late AccountRepositoryImpl repository;

  setUp(() {
    dataSource = _MockAccountDataSource();
    repository = AccountRepositoryImpl(dataSource);
  });

  test('개수 두 개를 그대로 담아 돌려준다', () async {
    when(
      dataSource.myContentSummary,
    ).thenAnswer((_) async => (postCount: 14, commentCount: 37));

    final result = await repository.myContentSummary();

    // Ok 는 == 를 정의하지 않아 감싼 값으로 비교한다 (core/result/result.dart).
    expect(result, isA<Ok<AccountContentSummary>>());
    expect(
      (result as Ok<AccountContentSummary>).value,
      const AccountContentSummary(postCount: 14, commentCount: 37),
    );
  });

  test('세션이 없으면 인증 실패로 돌려준다', () async {
    when(dataSource.myContentSummary).thenAnswer((_) async => null);

    final result = await repository.myContentSummary();

    expect(result, isA<Err<AccountContentSummary>>());
    final failure = (result as Err<AccountContentSummary>).failure;
    expect(failure, isA<AuthFailure>());
    expect((failure as AuthFailure).code, 'not_authenticated');
  });
}
