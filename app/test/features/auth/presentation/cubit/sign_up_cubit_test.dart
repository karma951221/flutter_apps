import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/auth/domain/entity/app_user.dart';
import 'package:daylog/features/auth/domain/usecase/auth_use_case.dart';
import 'package:daylog/features/auth/presentation/cubit/sign_up_cubit.dart';
import 'package:daylog/features/auth/presentation/cubit/submit_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthUseCase extends Mock implements AuthUseCase {}

const _user = AppUser(id: 'u1', email: 'a@b.com', nickname: 'tester');

void main() {
  late _MockAuthUseCase useCase;

  setUp(() => useCase = _MockAuthUseCase());

  void stubSignUp(Result<AppUser> result) {
    when(
      () => useCase.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        nickname: any(named: 'nickname'),
      ),
    ).thenAnswer((_) async => result);
  }

  blocTest<SignUpCubit, SubmitState>(
    '가입에 성공하면 success 로 끝난다',
    build: () {
      stubSignUp(const Ok(_user));
      return SignUpCubit(useCase);
    },
    act: (c) =>
        c.submit(email: 'a@b.com', password: 'abcd1234', nickname: 'tester'),
    expect: () => [const SubmitState.inProgress(), const SubmitState.success()],
  );

  blocTest<SignUpCubit, SubmitState>(
    '진행 중에 다시 누르면 무시한다',
    build: () {
      stubSignUp(const Ok(_user));
      return SignUpCubit(useCase);
    },
    act: (c) {
      c.submit(email: 'a@b.com', password: 'abcd1234', nickname: 'tester');
      c.submit(email: 'a@b.com', password: 'abcd1234', nickname: 'tester');
    },
    expect: () => [const SubmitState.inProgress(), const SubmitState.success()],
  );
}
