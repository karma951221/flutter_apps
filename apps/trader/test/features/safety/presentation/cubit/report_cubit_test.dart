import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/safety/domain/entity/report_reason.dart';
import 'package:daylog/features/safety/domain/entity/report_target.dart';
import 'package:daylog/features/safety/domain/usecase/safety_use_case.dart';
import 'package:daylog/features/safety/presentation/cubit/report_cubit.dart';
import 'package:daylog/features/safety/presentation/cubit/report_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportUseCase extends Mock implements SafetyUseCase {}

void main() {
  late _MockReportUseCase useCase;

  const target = ReportTarget.post('post-1');

  setUpAll(() {
    registerFallbackValue(const ReportTarget.post('_'));
    registerFallbackValue(ReportReason.spam);
  });

  setUp(() {
    useCase = _MockReportUseCase();
  });

  blocTest<ReportCubit, ReportState>(
    '사유를 고르면 상태에 반영된다',
    build: () => ReportCubit(useCase),
    act: (cubit) => cubit.selectReason(ReportReason.abuse),
    expect: () => [const ReportState(reason: ReportReason.abuse)],
  );

  blocTest<ReportCubit, ReportState>(
    '사유를 고르지 않으면 제출할 수 없다',
    build: () => ReportCubit(useCase),
    verify: (cubit) => expect(cubit.state.canSubmit, isFalse),
  );

  blocTest<ReportCubit, ReportState>(
    '제출은 진행 중을 켰다 끈다',
    setUp: () => when(
      () => useCase.submit(
        any(),
        reason: any(named: 'reason'),
        detail: any(named: 'detail'),
      ),
    ).thenAnswer((_) async => const Ok(null)),
    build: () => ReportCubit(useCase),
    seed: () => const ReportState(reason: ReportReason.spam),
    act: (cubit) => cubit.submit(target),
    expect: () => [
      const ReportState(reason: ReportReason.spam, isSubmitting: true),
      const ReportState(reason: ReportReason.spam),
    ],
  );

  blocTest<ReportCubit, ReportState>(
    '성공하면 true 를 돌려준다',
    setUp: () => when(
      () => useCase.submit(
        any(),
        reason: any(named: 'reason'),
        detail: any(named: 'detail'),
      ),
    ).thenAnswer((_) async => const Ok(null)),
    build: () => ReportCubit(useCase),
    seed: () => const ReportState(reason: ReportReason.spam),
    act: (cubit) async {
      final succeeded = await cubit.submit(target);
      expect(succeeded, isTrue);
    },
  );

  blocTest<ReportCubit, ReportState>(
    '실패하면 failure 를 담고 false 를 돌려준다',
    setUp: () => when(
      () => useCase.submit(
        any(),
        reason: any(named: 'reason'),
        detail: any(named: 'detail'),
      ),
    ).thenAnswer((_) async => const Err(Failure.network())),
    build: () => ReportCubit(useCase),
    seed: () => const ReportState(reason: ReportReason.spam),
    act: (cubit) async {
      final succeeded = await cubit.submit(target);
      expect(succeeded, isFalse);
    },
    verify: (cubit) {
      expect(cubit.state.failure, const Failure.network());
      expect(cubit.state.isSubmitting, isFalse);
    },
  );

  blocTest<ReportCubit, ReportState>(
    '정규화 전 원문을 usecase 로 그대로 전달한다',
    setUp: () => when(
      () => useCase.submit(
        any(),
        reason: any(named: 'reason'),
        detail: any(named: 'detail'),
      ),
    ).thenAnswer((_) async => const Ok(null)),
    build: () => ReportCubit(useCase),
    seed: () => const ReportState(reason: ReportReason.spam),
    act: (cubit) async {
      cubit.changeDetail('   ');
      await cubit.submit(target);
    },
    verify: (_) {
      verify(
        () => useCase.submit(target, reason: ReportReason.spam, detail: '   '),
      ).called(1);
    },
  );
}
