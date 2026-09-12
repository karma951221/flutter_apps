import 'package:core/core.dart';
import 'package:feature_safety/feature_safety.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockReportDataSource extends Mock implements ReportDataSource {}

void main() {
  late _MockReportDataSource dataSource;
  late ReportRepositoryImpl repository;

  const target = ReportTarget.post('post-1');

  setUpAll(() {
    registerFallbackValue(const ReportTarget.post('_'));
    registerFallbackValue(ReportReason.spam);
  });

  setUp(() {
    dataSource = _MockReportDataSource();
    repository = ReportRepositoryImpl(dataSource);
  });

  test('성공하면 Ok 를 돌려준다', () async {
    when(
      () => dataSource.submitReport(
        any(),
        reason: any(named: 'reason'),
        detail: any(named: 'detail'),
      ),
    ).thenAnswer((_) async {});

    final result = await repository.submitReport(
      target,
      reason: ReportReason.spam,
    );

    expect(result, isA<Ok<void>>());
  });

  test('중복 신고(reports_once) 는 ValidationFailure 로 변환된다', () async {
    when(
      () => dataSource.submitReport(
        any(),
        reason: any(named: 'reason'),
        detail: any(named: 'detail'),
      ),
    ).thenThrow(
      PostgrestException(
        message:
            'duplicate key value violates unique constraint "reports_once"',
        code: '23505',
      ),
    );

    final result = await repository.submitReport(
      target,
      reason: ReportReason.spam,
    );

    expect(result, isA<Err<void>>());
    final failure = (result as Err<void>).failure;
    expect(failure, isA<ValidationFailure>());
    expect((failure as ValidationFailure).message, '이미 신고한 항목입니다');
  });

  test('내 게시물 신고 트리거 문구가 같은 문구의 ValidationFailure 로 변환된다', () async {
    when(
      () => dataSource.submitReport(
        any(),
        reason: any(named: 'reason'),
        detail: any(named: 'detail'),
      ),
    ).thenThrow(
      PostgrestException(message: '내 게시물은 신고할 수 없습니다', code: 'P0001'),
    );

    final result = await repository.submitReport(
      target,
      reason: ReportReason.spam,
    );

    expect(result, isA<Err<void>>());
    final failure = (result as Err<void>).failure;
    expect(failure, isA<ValidationFailure>());
    expect((failure as ValidationFailure).message, '내 게시물은 신고할 수 없습니다');
  });
}
