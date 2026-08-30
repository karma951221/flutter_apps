import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/safety/domain/entity/blocked_user.dart';
import 'package:daylog/features/safety/domain/repository/block_repository.dart';
import 'package:daylog/features/safety/domain/usecase/scenario/get_blocked_users_scenario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBlockRepository extends Mock implements BlockRepository {}

void main() {
  late _MockBlockRepository repository;
  late GetBlockedUsersScenario scenario;

  setUp(() {
    repository = _MockBlockRepository();
    scenario = GetBlockedUsersScenario(repository);
  });

  test('repository.getBlockedUsers 의 결과를 그대로 돌려준다', () async {
    final users = [
      BlockedUser(
        id: 'user-1',
        nickname: 'daylog',
        blockedAt: DateTime.utc(2026, 8, 25),
      ),
    ];
    when(repository.getBlockedUsers).thenAnswer((_) async => Ok(users));

    final result = await scenario();

    expect(result, isA<Ok<List<BlockedUser>>>());
    expect((result as Ok<List<BlockedUser>>).value, users);
    verify(repository.getBlockedUsers).called(1);
  });

  test('repository 의 Err 를 그대로 돌려준다', () async {
    when(
      repository.getBlockedUsers,
    ).thenAnswer((_) async => const Err(Failure.network()));

    final result = await scenario();

    expect(result, isA<Err<List<BlockedUser>>>());
  });
}
