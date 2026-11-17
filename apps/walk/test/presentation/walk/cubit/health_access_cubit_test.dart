import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/walk/entity/health_access.dart';
import 'package:walk/domain/walk/usecase/walk_use_case.dart';
import 'package:walk/presentation/walk/cubit/health_access_cubit.dart';
import 'package:walk/presentation/walk/cubit/health_access_state.dart';

class _MockUseCase extends Mock implements WalkUseCase {}

void main() {
  late _MockUseCase useCase;
  setUp(() {
    useCase = _MockUseCase();
    when(() => useCase.permissionDeclinedThisSession).thenReturn(false);
  });

  test('처음은 확인 중(access null)', () {
    expect(HealthAccessCubit(useCase).state, const HealthAccessState());
  });

  blocTest<HealthAccessCubit, HealthAccessState>(
    'check 는 확인한 상태와 거부 여부를 담는다',
    build: () {
      when(
        () => useCase.access(),
      ).thenAnswer((_) async => HealthAccess.permissionDenied);
      when(() => useCase.permissionDeclinedThisSession).thenReturn(true);
      return HealthAccessCubit(useCase);
    },
    act: (cubit) => cubit.check(),
    expect: () => [
      const HealthAccessState(
        access: HealthAccess.permissionDenied,
        canOpenSettings: true,
      ),
    ],
  );

  blocTest<HealthAccessCubit, HealthAccessState>(
    'request 는 요청 뒤 상태를 담는다',
    build: () {
      when(
        () => useCase.requestAccess(),
      ).thenAnswer((_) async => HealthAccess.granted);
      return HealthAccessCubit(useCase);
    },
    act: (cubit) => cubit.request(),
    expect: () => [const HealthAccessState(access: HealthAccess.granted)],
  );

  blocTest<HealthAccessCubit, HealthAccessState>(
    'openInstall · openSettings 는 화면만 열고 상태는 복귀 때 다시 확인한다',
    build: () {
      when(() => useCase.openInstall()).thenAnswer((_) async {});
      when(() => useCase.openPermissionSettings()).thenAnswer((_) async {});
      return HealthAccessCubit(useCase);
    },
    act: (cubit) async {
      await cubit.openInstall();
      await cubit.openSettings();
    },
    expect: () => <HealthAccessState>[],
    verify: (_) {
      verify(() => useCase.openInstall()).called(1);
      verify(() => useCase.openPermissionSettings()).called(1);
    },
  );
}
