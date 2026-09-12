import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:daylog/features/auth/domain/usecase/auth_use_case.dart';
import 'package:daylog/features/settings/presentation/cubit/change_password_cubit.dart';
import 'package:daylog/features/settings/presentation/cubit/change_password_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthUseCase extends Mock implements AuthUseCase {}

void main() {
  late _MockAuthUseCase useCase;

  setUp(() => useCase = _MockAuthUseCase());

  blocTest<ChangePasswordCubit, ChangePasswordState>(
    '변경에 성공하면 진행 중을 거쳐 성공 상태가 된다',
    build: () {
      when(
        () => useCase.updatePassword(any()),
      ).thenAnswer((_) async => const Ok(null));
      return ChangePasswordCubit(useCase);
    },
    act: (c) => c.submit('new-password'),
    expect: () => [
      const ChangePasswordState.inProgress(),
      const ChangePasswordState.success(),
    ],
    verify: (_) =>
        verify(() => useCase.updatePassword('new-password')).called(1),
  );

  blocTest<ChangePasswordCubit, ChangePasswordState>(
    '변경에 실패하면 실패를 그대로 들고 있는다',
    build: () {
      when(() => useCase.updatePassword(any())).thenAnswer(
        (_) async => const Err(Failure.auth(message: '세션이 만료되었습니다')),
      );
      return ChangePasswordCubit(useCase);
    },
    act: (c) => c.submit('new-password'),
    expect: () => [
      const ChangePasswordState.inProgress(),
      isA<ChangePasswordFailure>().having(
        (s) => s.failure,
        'failure',
        isA<AuthFailure>(),
      ),
    ],
  );

  blocTest<ChangePasswordCubit, ChangePasswordState>(
    '진행 중에 다시 제출해도 요청은 한 번만 나간다',
    build: () {
      when(() => useCase.updatePassword(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const Ok(null);
      });
      return ChangePasswordCubit(useCase);
    },
    act: (c) async {
      final first = c.submit('new-password');
      await c.submit('new-password');
      await first;
    },
    expect: () => [
      const ChangePasswordState.inProgress(),
      const ChangePasswordState.success(),
    ],
    verify: (_) => verify(() => useCase.updatePassword(any())).called(1),
  );
}
