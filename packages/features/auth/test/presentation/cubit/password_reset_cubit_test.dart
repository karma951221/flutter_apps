import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthUseCase extends Mock implements AuthUseCase {}

void main() {
  late _MockAuthUseCase useCase;

  setUp(() => useCase = _MockAuthUseCase());

  blocTest<PasswordResetCubit, PasswordResetState>(
    '코드 발송에 성공하면 코드 입력 단계로 넘어가고 이메일을 기억한다',
    build: () {
      when(
        () => useCase.sendPasswordResetCode(any()),
      ).thenAnswer((_) async => const Ok(null));
      return PasswordResetCubit(useCase);
    },
    act: (c) => c.sendCode(' a@b.com '),
    expect: () => [
      isA<PasswordResetState>().having((s) => s.isLoading, 'isLoading', true),
      isA<PasswordResetState>()
          .having((s) => s.step, 'step', PasswordResetStep.verifyCode)
          .having((s) => s.email, 'email', 'a@b.com'),
    ],
  );

  blocTest<PasswordResetCubit, PasswordResetState>(
    '코드 발송에 실패하면 단계를 넘기지 않는다',
    build: () {
      when(
        () => useCase.sendPasswordResetCode(any()),
      ).thenAnswer((_) async => const Err(Failure.network()));
      return PasswordResetCubit(useCase);
    },
    act: (c) => c.sendCode('a@b.com'),
    expect: () => [
      isA<PasswordResetState>().having((s) => s.isLoading, 'isLoading', true),
      isA<PasswordResetState>()
          .having((s) => s.step, 'step', PasswordResetStep.requestCode)
          .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
    ],
  );

  blocTest<PasswordResetCubit, PasswordResetState>(
    '코드가 틀리면 새 비밀번호 단계로 넘어가지 않는다',
    build: () {
      when(
        () => useCase.verifyPasswordResetCode(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      ).thenAnswer((_) async => const Err(Failure.auth(code: 'otp_expired')));
      return PasswordResetCubit(useCase);
    },
    act: (c) => c.verifyCode('000000'),
    expect: () => [
      isA<PasswordResetState>().having((s) => s.isLoading, 'isLoading', true),
      isA<PasswordResetState>()
          .having((s) => s.step, 'step', PasswordResetStep.requestCode)
          .having((s) => s.failure, 'failure', isA<AuthFailure>()),
    ],
  );

  blocTest<PasswordResetCubit, PasswordResetState>(
    '비밀번호 변경에 성공하면 done 으로 끝난다',
    build: () {
      when(
        () => useCase.updatePassword(any()),
      ).thenAnswer((_) async => const Ok(null));
      return PasswordResetCubit(useCase);
    },
    act: (c) => c.updatePassword('brand-new-pass'),
    expect: () => [
      isA<PasswordResetState>().having((s) => s.isLoading, 'isLoading', true),
      isA<PasswordResetState>().having(
        (s) => s.step,
        'step',
        PasswordResetStep.done,
      ),
    ],
  );

  blocTest<PasswordResetCubit, PasswordResetState>(
    '이메일 다시 입력을 누르면 1단계로 돌아가고 오류를 지운다',
    build: () => PasswordResetCubit(useCase),
    seed: () => const PasswordResetState(
      step: PasswordResetStep.verifyCode,
      failure: Failure.auth(),
    ),
    act: (c) => c.backToEmail(),
    expect: () => [
      isA<PasswordResetState>()
          .having((s) => s.step, 'step', PasswordResetStep.requestCode)
          .having((s) => s.failure, 'failure', isNull),
    ],
  );
}
