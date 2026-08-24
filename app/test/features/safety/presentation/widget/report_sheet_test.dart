import 'package:daylog/core/di/injection.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/design_system/widget/app_button.dart';
import 'package:daylog/features/safety/domain/entity/report_reason.dart';
import 'package:daylog/features/safety/domain/entity/report_target.dart';
import 'package:daylog/features/safety/domain/usecase/report_use_case.dart';
import 'package:daylog/features/safety/presentation/cubit/report_cubit.dart';
import 'package:daylog/features/safety/presentation/widget/report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportUseCase extends Mock implements ReportUseCase {}

void main() {
  late _MockReportUseCase useCase;

  const target = ReportTarget.post('post-1');

  setUpAll(() {
    registerFallbackValue(const ReportTarget.post('_'));
    registerFallbackValue(ReportReason.spam);
  });

  setUp(() {
    useCase = _MockReportUseCase();
    getIt.registerFactory<ReportCubit>(() => ReportCubit(useCase));
  });

  tearDown(getIt.reset);

  Future<bool?> pumpAndOpen(WidgetTester tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await ReportSheet.show(context, target);
              },
              child: const Text('신고'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('신고'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('사유 5개가 모두 보인다', (tester) async {
    await pumpAndOpen(tester);

    for (final reason in ReportReason.values) {
      expect(find.text(reason.label), findsOneWidget);
    }
  });

  testWidgets('사유를 고르기 전에는 제출 버튼이 비활성이다', (tester) async {
    await pumpAndOpen(tester);

    final button = tester.widget<AppButton>(find.byType(AppButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('상세 설명 입력칸이 처음부터 보인다', (tester) async {
    await pumpAndOpen(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('상세 설명 (선택)'), findsOneWidget);
  });

  testWidgets('제출에 성공하면 시트가 닫힌다', (tester) async {
    when(
      () => useCase.submit(
        any(),
        reason: any(named: 'reason'),
        detail: any(named: 'detail'),
      ),
    ).thenAnswer((_) async => const Ok(null));

    Future<bool?>? resultFuture;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                resultFuture = ReportSheet.show(context, target);
              },
              child: const Text('신고'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('신고'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(ReportReason.spam.label));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, '신고하기'));
    await tester.pumpAndSettle();

    expect(find.text('신고하기'), findsNothing);
    expect(await resultFuture, isTrue);
  });

  testWidgets('제출에 실패하면 시트가 열려 있고 오류 문구가 보인다', (tester) async {
    when(
      () => useCase.submit(
        any(),
        reason: any(named: 'reason'),
        detail: any(named: 'detail'),
      ),
    ).thenAnswer((_) async => const Err(Failure.network(message: '연결 실패')));

    await pumpAndOpen(tester);

    await tester.tap(find.text(ReportReason.spam.label));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, '신고하기'));
    await tester.pumpAndSettle();

    expect(find.text('신고하기'), findsOneWidget);
    expect(find.text('연결 실패'), findsOneWidget);
  });
}
