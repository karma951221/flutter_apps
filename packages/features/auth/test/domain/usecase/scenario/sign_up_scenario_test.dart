import 'package:core/core.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _user = AppUser(id: 'u1', email: 'a@b.com', nickname: 'tester');

void main() {
  late _MockAuthRepository repository;
  late SignUpScenario scenario;

  setUp(() {
    repository = _MockAuthRepository();
    scenario = SignUpScenario(repository);
  });

  test('사용 중인 닉네임이면 가입을 시도하지 않는다', () async {
    when(
      () => repository.isNicknameAvailable('taken'),
    ).thenAnswer((_) async => const Ok(false));

    final result = await scenario(
      email: 'a@b.com',
      password: 'abcd1234',
      nickname: 'taken',
    );

    expect(result, isA<Err<AppUser>>());
    expect((result as Err<AppUser>).failure, isA<ValidationFailure>());
    verifyNever(
      () => repository.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        nickname: any(named: 'nickname'),
      ),
    );
  });

  test('닉네임 확인 실패는 가입을 막지 않는다', () async {
    when(
      () => repository.isNicknameAvailable('tester'),
    ).thenAnswer((_) async => const Err(Failure.network()));
    when(
      () => repository.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        nickname: any(named: 'nickname'),
      ),
    ).thenAnswer((_) async => const Ok(_user));

    final result = await scenario(
      email: 'a@b.com',
      password: 'abcd1234',
      nickname: 'tester',
    );

    expect(result, const Ok(_user));
    verify(
      () => repository.signUp(
        email: 'a@b.com',
        password: 'abcd1234',
        nickname: 'tester',
      ),
    ).called(1);
  });
}
