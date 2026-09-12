import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:feature_safety/feature_safety.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSafetyUseCase extends Mock implements SafetyUseCase {}

void main() {
  late _MockSafetyUseCase useCase;

  final user = BlockedUser(
    id: 'blocked-1',
    nickname: '이웃',
    avatarUrl: null,
    blockedAt: DateTime.utc(2026, 8, 25),
  );

  setUpAll(() {
    registerFallbackValue('_');
  });

  setUp(() {
    useCase = _MockSafetyUseCase();
  });

  blocTest<BlockedUsersCubit, BlockedUsersState>(
    '조회에 성공하면 목록을 담는다',
    setUp: () => when(
      () => useCase.getBlockedUsers(),
    ).thenAnswer((_) async => Ok([user])),
    build: () => BlockedUsersCubit(useCase),
    act: (cubit) => cubit.load(),
    expect: () => [
      const BlockedUsersState(),
      BlockedUsersState(status: BlockedUsersStatus.loaded, items: [user]),
    ],
  );

  blocTest<BlockedUsersCubit, BlockedUsersState>(
    '조회에 실패하면 failure 를 담는다',
    setUp: () => when(
      () => useCase.getBlockedUsers(),
    ).thenAnswer((_) async => const Err(Failure.network())),
    build: () => BlockedUsersCubit(useCase),
    act: (cubit) => cubit.load(),
    expect: () => [
      const BlockedUsersState(),
      const BlockedUsersState(
        status: BlockedUsersStatus.failure,
        failure: Failure.network(),
      ),
    ],
  );

  blocTest<BlockedUsersCubit, BlockedUsersState>(
    '해제에 성공하면 그 사용자를 목록에서 걷어내고 true 를 돌려준다',
    setUp: () => when(
      () => useCase.unblockUser(any()),
    ).thenAnswer((_) async => const Ok(null)),
    build: () => BlockedUsersCubit(useCase),
    seed: () =>
        BlockedUsersState(status: BlockedUsersStatus.loaded, items: [user]),
    act: (cubit) async {
      final succeeded = await cubit.unblock(user.id);
      expect(succeeded, isTrue);
    },
    expect: () => [
      const BlockedUsersState(status: BlockedUsersStatus.loaded, items: []),
    ],
    verify: (_) {
      verify(() => useCase.unblockUser(user.id)).called(1);
    },
  );

  blocTest<BlockedUsersCubit, BlockedUsersState>(
    '해제에 실패하면 목록을 그대로 두고 false 를 돌려준다',
    setUp: () => when(
      () => useCase.unblockUser(any()),
    ).thenAnswer((_) async => const Err(Failure.network())),
    build: () => BlockedUsersCubit(useCase),
    seed: () =>
        BlockedUsersState(status: BlockedUsersStatus.loaded, items: [user]),
    act: (cubit) async {
      final succeeded = await cubit.unblock(user.id);
      expect(succeeded, isFalse);
    },
    expect: () => [],
  );
}
