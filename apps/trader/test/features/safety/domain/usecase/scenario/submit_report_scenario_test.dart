import 'package:core/core.dart';
import 'package:daylog/features/safety/domain/entity/report_reason.dart';
import 'package:daylog/features/safety/domain/entity/report_target.dart';
import 'package:daylog/features/safety/domain/repository/report_repository.dart';
import 'package:daylog/features/safety/domain/usecase/scenario/submit_report_scenario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late _MockReportRepository repository;
  late SubmitReportScenario scenario;

  const target = ReportTarget.post('post-1');

  setUpAll(() {
    registerFallbackValue(const ReportTarget.post('_'));
    registerFallbackValue(ReportReason.spam);
  });

  setUp(() {
    repository = _MockReportRepository();
    scenario = SubmitReportScenario(repository);
  });

  test('정규화된 detail 로 repository 를 부른다', () async {
    when(
      () => repository.submitReport(
        any(),
        reason: any(named: 'reason'),
        detail: any(named: 'detail'),
      ),
    ).thenAnswer((_) async => const Ok(null));

    await scenario(target, reason: ReportReason.spam, detail: '   ');

    verify(
      () => repository.submitReport(
        target,
        reason: ReportReason.spam,
        detail: null,
      ),
    ).called(1);
  });

  test('내용이 있는 detail 은 다듬어져 전달된다', () async {
    when(
      () => repository.submitReport(
        any(),
        reason: any(named: 'reason'),
        detail: any(named: 'detail'),
      ),
    ).thenAnswer((_) async => const Ok(null));

    await scenario(target, reason: ReportReason.abuse, detail: ' 욕설 ');

    verify(
      () => repository.submitReport(
        target,
        reason: ReportReason.abuse,
        detail: '욕설',
      ),
    ).called(1);
  });

  test('repository 의 Err 를 그대로 돌려준다', () async {
    when(
      () => repository.submitReport(
        any(),
        reason: any(named: 'reason'),
        detail: any(named: 'detail'),
      ),
    ).thenAnswer((_) async => const Err(Failure.network()));

    final result = await scenario(target, reason: ReportReason.spam);

    expect(result, isA<Err<void>>());
  });
}
