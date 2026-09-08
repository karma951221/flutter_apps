import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/auth/domain/repository/auth_repository.dart';
import 'package:daylog/features/auth/domain/usecase/scenario/check_nickname_availability_scenario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late CheckNicknameAvailabilityScenario scenario;

  setUp(() {
    repository = _MockAuthRepository();
    scenario = CheckNicknameAvailabilityScenario(repository);
  });

  test('저장소의 판단을 그대로 전한다', () async {
    when(
      () => repository.isNicknameAvailable('tester'),
    ).thenAnswer((_) async => const Ok(true));

    final result = await scenario('tester');

    expect(result, isA<Ok<bool>>());
    expect((result as Ok<bool>).value, isTrue);
    verify(() => repository.isNicknameAvailable('tester')).called(1);
  });

  test('확인 실패도 그대로 전한다', () async {
    when(
      () => repository.isNicknameAvailable('tester'),
    ).thenAnswer((_) async => const Err(Failure.network()));

    expect(await scenario('tester'), isA<Err<bool>>());
  });
}
