import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/safety/domain/repository/block_repository.dart';
import 'package:daylog/features/safety/domain/usecase/scenario/unblock_user_scenario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBlockRepository extends Mock implements BlockRepository {}

void main() {
  late _MockBlockRepository repository;
  late UnblockUserScenario scenario;

  setUp(() {
    repository = _MockBlockRepository();
    scenario = UnblockUserScenario(repository);
  });

  test('repository.unblockUser 를 그대로 호출한다', () async {
    when(
      () => repository.unblockUser('user-1'),
    ).thenAnswer((_) async => const Ok(null));

    final result = await scenario('user-1');

    expect(result, isA<Ok<void>>());
    verify(() => repository.unblockUser('user-1')).called(1);
  });

  test('repository 의 Err 를 그대로 돌려준다', () async {
    when(
      () => repository.unblockUser('user-1'),
    ).thenAnswer((_) async => const Err(Failure.network()));

    final result = await scenario('user-1');

    expect(result, isA<Err<void>>());
  });
}
