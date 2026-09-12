import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:daylog/features/auth/domain/usecase/auth_use_case.dart';
import 'package:daylog/features/settings/presentation/cubit/delete_account_cubit.dart';
import 'package:daylog/features/settings/presentation/cubit/delete_account_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthUseCase extends Mock implements AuthUseCase {}

void main() {
  late _MockAuthUseCase useCase;

  setUp(() => useCase = _MockAuthUseCase());

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    '성공하면 진행 중 상태로 남는다 — 화면째로 사라질 것이므로 되돌리지 않는다',
    setUp: () => when(
      () => useCase.deleteAccount(),
    ).thenAnswer((_) async => const Ok(null)),
    build: () => DeleteAccountCubit(useCase),
    act: (cubit) => cubit.submit(),
    expect: () => const [DeleteAccountState.inProgress()],
    verify: (_) => verify(() => useCase.deleteAccount()).called(1),
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    '실패하면 실패 상태로 남는다',
    setUp: () => when(
      () => useCase.deleteAccount(),
    ).thenAnswer((_) async => const Err(Failure.network())),
    build: () => DeleteAccountCubit(useCase),
    act: (cubit) => cubit.submit(),
    expect: () => const [
      DeleteAccountState.inProgress(),
      DeleteAccountState.failure(Failure.network()),
    ],
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    '진행 중에는 다시 부를 수 없다',
    setUp: () => when(() => useCase.deleteAccount()).thenAnswer(
      (_) => Future.delayed(const Duration(days: 1), () => const Ok(null)),
    ),
    build: () => DeleteAccountCubit(useCase),
    act: (cubit) {
      cubit.submit();
      cubit.submit();
    },
    expect: () => const [DeleteAccountState.inProgress()],
    verify: (_) => verify(() => useCase.deleteAccount()).called(1),
  );
}
