import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/presentation/social/cubit/auth_cubit.dart';
import 'package:pawlog/presentation/social/cubit/auth_form_state.dart';

import '../../../support/mock_social_use_case.dart';

void main() {
  late MockSocialUseCase useCase;

  const nicknameTaken = Failure.validation(
    field: 'nickname',
    failureCode: FailureCode.nicknameTaken,
  );
  const badCredentials = Failure.auth(
    failureCode: FailureCode.invalidCredentials,
  );

  setUp(() => useCase = MockSocialUseCase());

  blocTest<AuthCubit, AuthFormState>(
    '로그인이 성공하면 submitting 뒤 succeeded',
    setUp: () => when(
      () => useCase.signIn('a@b.com', 'password1'),
    ).thenAnswer((_) async => const Ok(null)),
    build: () => AuthCubit(useCase),
    act: (cubit) => cubit.signIn(email: 'a@b.com', password: 'password1'),
    expect: () => const [AuthFormState.submitting(), AuthFormState.succeeded()],
  );

  blocTest<AuthCubit, AuthFormState>(
    '로그인이 실패하면 failed 에 실패를 담는다',
    setUp: () => when(
      () => useCase.signIn(any(), any()),
    ).thenAnswer((_) async => const Err(badCredentials)),
    build: () => AuthCubit(useCase),
    act: (cubit) => cubit.signIn(email: 'a@b.com', password: 'wrong'),
    expect: () => const [
      AuthFormState.submitting(),
      AuthFormState.failed(badCredentials),
    ],
  );

  blocTest<AuthCubit, AuthFormState>(
    '가입이 성공하면 succeeded',
    setUp: () => when(
      () => useCase.signUp('a@b.com', 'password1', '콩이네'),
    ).thenAnswer((_) async => const Ok(null)),
    build: () => AuthCubit(useCase),
    act: (cubit) =>
        cubit.signUp(email: 'a@b.com', password: 'password1', nickname: '콩이네'),
    expect: () => const [AuthFormState.submitting(), AuthFormState.succeeded()],
  );

  blocTest<AuthCubit, AuthFormState>(
    '닉네임이 겹치면 nicknameTaken 실패가 된다',
    setUp: () => when(
      () => useCase.signUp(any(), any(), any()),
    ).thenAnswer((_) async => const Err(nicknameTaken)),
    build: () => AuthCubit(useCase),
    act: (cubit) =>
        cubit.signUp(email: 'a@b.com', password: 'password1', nickname: '콩이네'),
    expect: () => const [
      AuthFormState.submitting(),
      AuthFormState.failed(nicknameTaken),
    ],
  );

  blocTest<AuthCubit, AuthFormState>(
    '보내는 중에는 두 번째 요청을 무시한다',
    setUp: () => when(
      () => useCase.signIn(any(), any()),
    ).thenAnswer((_) async => const Ok(null)),
    build: () => AuthCubit(useCase),
    seed: () => const AuthFormState.submitting(),
    act: (cubit) => cubit.signIn(email: 'a@b.com', password: 'password1'),
    expect: () => const <AuthFormState>[],
    verify: (_) => verifyNever(() => useCase.signIn(any(), any())),
  );
}
