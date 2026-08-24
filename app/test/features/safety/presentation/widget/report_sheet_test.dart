import 'package:daylog/core/di/injection.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/design_system/widget/app_button.dart';
import 'package:daylog/features/safety/domain/entity/report_reason.dart';
import 'package:daylog/features/safety/domain/entity/report_target.dart';
import 'package:daylog/features/safety/domain/usecase/safety_use_case.dart';
import 'package:daylog/features/safety/presentation/cubit/report_cubit.dart';
import 'package:daylog/features/safety/presentation/widget/report_sheet.dart';
import 'package:flutter/material.dart';
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

  testWidgets('작은 화면에 키보드가 올라와도 시트가 스크롤되어 제출 버튼을 누를 수 있다', (tester) async {
    // 375x667(iPhone 8급) 화면 + 키보드로 인한 260 논리픽셀 bottom inset을
    // 흉내낸다. 시트 내용(~530dp)이 남은 높이를 넘어서야 오버플로/탭 불가
    // 재현이 된다 — 기본 800x600 테스트 서피스는 이 문제를 절대 못 잡는다.
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.reset);

    when(
      () => useCase.submit(
        any(),
        reason: any(named: 'reason'),
        detail: any(named: 'detail'),
      ),
    ).thenAnswer((_) async => const Ok(null));

    await pumpAndOpen(tester);

    await tester.tap(find.text(ReportReason.spam.label));
    await tester.pumpAndSettle();

    // 스크롤하지 않으면 버튼이 화면 밖(오버플로 영역)에 있어 hit-test가
    // 닿지 않는다. ensureVisible로 스크롤한 뒤에도 탭이 되는지가 곧
    // "스크롤 가능한가"의 증거다.
    final buttonFinder = find.widgetWithText(AppButton, '신고하기');
    await tester.ensureVisible(buttonFinder);
    await tester.pumpAndSettle();

    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(find.text('신고하기'), findsNothing);
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
