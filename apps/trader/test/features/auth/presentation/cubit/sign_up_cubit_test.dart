import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/core/validation/nickname_check.dart';
import 'package:daylog/features/auth/domain/entity/app_user.dart';
import 'package:daylog/features/auth/domain/usecase/auth_use_case.dart';
import 'package:daylog/features/auth/presentation/cubit/sign_up_cubit.dart';
import 'package:daylog/features/auth/presentation/cubit/sign_up_state.dart';
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

  blocTest<SignUpCubit, SignUpState>(
    '가입에 성공하면 success 로 끝난다',
    build: () {
      stubSignUp(const Ok(_user));
      return SignUpCubit(useCase);
    },
    act: (c) =>
        c.submit(email: 'a@b.com', password: 'abcd1234', nickname: 'tester'),
    expect: () => [
      const SignUpState(submit: SubmitState.inProgress()),
      const SignUpState(submit: SubmitState.success()),
    ],
  );

  blocTest<SignUpCubit, SignUpState>(
    '진행 중에 다시 누르면 무시한다',
    build: () {
      stubSignUp(const Ok(_user));
      return SignUpCubit(useCase);
    },
    act: (c) {
      c.submit(email: 'a@b.com', password: 'abcd1234', nickname: 'tester');
      c.submit(email: 'a@b.com', password: 'abcd1234', nickname: 'tester');
    },
    expect: () => [
      const SignUpState(submit: SubmitState.inProgress()),
      const SignUpState(submit: SubmitState.success()),
    ],
  );

  group('닉네임 사전 확인', () {
    // 디바운스가 지나 조회까지 끝나기를 기다린다.
    Future<void> settle() => Future<void>.delayed(
      nicknameCheckDebounce + const Duration(milliseconds: 100),
    );

    test('입력이 멎은 뒤 마지막 값만 한 번 조회하고 사용 가능을 알린다', () async {
      when(
        () => useCase.isNicknameAvailable(any()),
      ).thenAnswer((_) async => const Ok(true));
      final cubit = SignUpCubit(useCase);

      cubit.checkNickname('새이');
      cubit.checkNickname('새이름');
      expect(cubit.state.nicknameCheck, isA<NicknameCheckChecking>());
      await settle();

      expect(cubit.state.nicknameCheck, isA<NicknameCheckAvailable>());
      verify(() => useCase.isNicknameAvailable('새이름')).called(1);
      verifyNever(() => useCase.isNicknameAvailable('새이'));
      await cubit.close();
    });

    test('이미 쓰이는 닉네임이면 중복으로 알린다', () async {
      when(
        () => useCase.isNicknameAvailable(any()),
      ).thenAnswer((_) async => const Ok(false));
      final cubit = SignUpCubit(useCase);

      cubit.checkNickname('  겹치는이름  ');
      await settle();

      expect(cubit.state.nicknameCheck, isA<NicknameCheckTaken>());
      verify(() => useCase.isNicknameAvailable('겹치는이름')).called(1);
      await cubit.close();
    });

    test('형식이 어긋난 닉네임은 조회하지 않는다', () async {
      final cubit = SignUpCubit(useCase);

      cubit.checkNickname('짧');
      await settle();

      expect(cubit.state.nicknameCheck, isA<NicknameCheckIdle>());
      verifyNever(() => useCase.isNicknameAvailable(any()));
      await cubit.close();
    });

    test('확인에 실패하면 아무 말도 하지 않는다', () async {
      when(
        () => useCase.isNicknameAvailable(any()),
      ).thenAnswer((_) async => const Err(Failure.network()));
      final cubit = SignUpCubit(useCase);

      cubit.checkNickname('새이름');
      await settle();

      expect(cubit.state.nicknameCheck, isA<NicknameCheckIdle>());
      await cubit.close();
    });

    test('제출 결과는 사전 확인 결과를 지운다', () async {
      when(
        () => useCase.isNicknameAvailable(any()),
      ).thenAnswer((_) async => const Ok(true));
      stubSignUp(const Ok(_user));
      final cubit = SignUpCubit(useCase);

      cubit.checkNickname('새이름');
      await settle();
      expect(cubit.state.nicknameCheck, isA<NicknameCheckAvailable>());

      await cubit.submit(
        email: 'a@b.com',
        password: 'abcd1234',
        nickname: '새이름',
      );

      expect(cubit.state.nicknameCheck, isA<NicknameCheckIdle>());
      await cubit.close();
    });

    // 화면을 떠나면 BlocProvider 가 cubit 을 닫는다. 그때 디바운스 타이머가
    // 살아 있으면 닫힌 cubit 에 emit 해 bloc 이 예외를 던진다.
    test('닫힌 뒤에는 아무것도 내지 않는다', () async {
      when(
        () => useCase.isNicknameAvailable(any()),
      ).thenAnswer((_) async => const Ok(true));
      final cubit = SignUpCubit(useCase);

      cubit.checkNickname('새이름');
      await cubit.close();
      await settle();

      verifyNever(() => useCase.isNicknameAvailable(any()));
    });
  });
}
