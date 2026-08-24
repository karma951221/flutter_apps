import 'package:daylog/core/di/injection.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/auth/domain/usecase/auth_use_case.dart';
import 'package:daylog/features/settings/presentation/cubit/delete_account_cubit.dart';
import 'package:daylog/features/settings/presentation/page/account_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthUseCase extends Mock implements AuthUseCase {}

void main() {
  late _MockAuthUseCase useCase;

  setUp(() {
    useCase = _MockAuthUseCase();
    getIt.registerFactory<DeleteAccountCubit>(
      () => DeleteAccountCubit(useCase),
    );
  });

  tearDown(getIt.reset);

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const AccountSettingsPage()),
    );
    await tester.pump();
  }

  testWidgets('계정 설정은 비밀번호 변경과 회원 탈퇴 두 항목을 보여준다', (tester) async {
    await pumpPage(tester);

    expect(find.text('비밀번호 변경'), findsOneWidget);
    expect(find.text('회원 탈퇴'), findsOneWidget);
    expect(find.text('계정과 모든 기록이 즉시 삭제됩니다'), findsOneWidget);
  });

  testWidgets('탈퇴는 지워질 것을 보여주는 확인을 거쳐야 실행된다', (tester) async {
    when(() => useCase.deleteAccount()).thenAnswer((_) async => const Ok(null));

    await pumpPage(tester);
    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();

    // 다이얼로그를 띄운 것만으로는 아무것도 지우지 않는다.
    expect(find.text('정말 탈퇴할까요?'), findsOneWidget);
    expect(find.textContaining('작성한 게시물과 사진'), findsOneWidget);
    verifyNever(() => useCase.deleteAccount());

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    verifyNever(() => useCase.deleteAccount());

    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '탈퇴'));
    await tester.pumpAndSettle();

    verify(() => useCase.deleteAccount()).called(1);
  });

  testWidgets('탈퇴가 실패하면 Snackbar 로 알리고 화면에 남는다', (tester) async {
    when(
      () => useCase.deleteAccount(),
    ).thenAnswer((_) async => const Err(Failure.network()));

    await pumpPage(tester);
    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '탈퇴'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('회원 탈퇴'), findsOneWidget);
  });
}
