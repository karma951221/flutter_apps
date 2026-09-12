import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:daylog/features/safety/domain/usecase/safety_use_case.dart';
import 'package:daylog/features/safety/presentation/cubit/block_action_cubit.dart';
import 'package:daylog/features/safety/presentation/cubit/block_action_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSafetyUseCase extends Mock implements SafetyUseCase {}

void main() {
  late _MockSafetyUseCase useCase;

  setUp(() => useCase = _MockSafetyUseCase());

  blocTest<BlockActionCubit, BlockActionState>(
    '상태 조회 성공은 내가 건 차단 상태를 담는다',
    setUp: () => when(
      () => useCase.isBlockedByMe('user-1'),
    ).thenAnswer((_) async => const Ok(true)),
    build: () => BlockActionCubit(useCase),
    act: (cubit) => cubit.loadStatus('user-1'),
    expect: () => [
      const BlockActionState(isLoadingStatus: true),
      const BlockActionState(isBlocked: true),
    ],
  );

  blocTest<BlockActionCubit, BlockActionState>(
    '상태 조회 실패는 미확인 상태와 failure를 담는다',
    setUp: () => when(
      () => useCase.isBlockedByMe('user-1'),
    ).thenAnswer((_) async => const Err(Failure.network())),
    build: () => BlockActionCubit(useCase),
    act: (cubit) => cubit.loadStatus('user-1'),
    expect: () => [
      const BlockActionState(isLoadingStatus: true),
      const BlockActionState(failure: Failure.network()),
    ],
  );

  blocTest<BlockActionCubit, BlockActionState>(
    '차단 성공은 isBlocked를 true로 전환한다',
    setUp: () => when(
      () => useCase.blockUser('user-1'),
    ).thenAnswer((_) async => const Ok(null)),
    build: () => BlockActionCubit(useCase),
    seed: () => const BlockActionState(isBlocked: false),
    act: (cubit) => cubit.block('user-1'),
    expect: () => [
      const BlockActionState(isBlocking: true, isBlocked: false),
      const BlockActionState(isBlocked: true),
    ],
  );

  blocTest<BlockActionCubit, BlockActionState>(
    '차단 해제 성공은 isBlocked를 false로 전환한다',
    setUp: () => when(
      () => useCase.unblockUser('user-1'),
    ).thenAnswer((_) async => const Ok(null)),
    build: () => BlockActionCubit(useCase),
    seed: () => const BlockActionState(isBlocked: true),
    act: (cubit) => cubit.unblock('user-1'),
    expect: () => [
      const BlockActionState(isBlocking: true, isBlocked: true),
      const BlockActionState(isBlocked: false),
    ],
  );

  blocTest<BlockActionCubit, BlockActionState>(
    '동작 실패는 상태를 유지하고 failure를 전달한다',
    setUp: () => when(
      () => useCase.unblockUser('user-1'),
    ).thenAnswer((_) async => const Err(Failure.network())),
    build: () => BlockActionCubit(useCase),
    seed: () => const BlockActionState(isBlocked: true),
    act: (cubit) => cubit.unblock('user-1'),
    expect: () => [
      const BlockActionState(isBlocking: true, isBlocked: true),
      const BlockActionState(isBlocked: true, failure: Failure.network()),
    ],
  );
}
