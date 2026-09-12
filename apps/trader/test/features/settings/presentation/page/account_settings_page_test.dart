import 'dart:async';

import 'package:core/core.dart';
import 'package:l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:daylog/features/auth/domain/usecase/auth_use_case.dart';
import 'package:daylog/features/settings/domain/entity/account_content_summary.dart';
import 'package:daylog/features/settings/domain/usecase/account_use_case.dart';
import 'package:daylog/features/settings/presentation/cubit/delete_account_cubit.dart';
import 'package:daylog/features/settings/presentation/page/account_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthUseCase extends Mock implements AuthUseCase {}

class _MockAccountUseCase extends Mock implements AccountUseCase {}

void main() {
  late _MockAuthUseCase useCase;
  late _MockAccountUseCase accountUseCase;

  setUp(() {
    useCase = _MockAuthUseCase();
    accountUseCase = _MockAccountUseCase();
    when(accountUseCase.myContentSummary).thenAnswer(
      (_) async =>
          const Ok(AccountContentSummary(postCount: 14, commentCount: 37)),
    );
    getIt
      ..registerFactory<DeleteAccountCubit>(() => DeleteAccountCubit(useCase))
      // 확인 다이얼로그를 열 때 화면이 직접 꺼내 쓴다.
      ..registerSingleton<AccountUseCase>(accountUseCase);
  });

  tearDown(getIt.reset);

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        // ko 가 ARB template 언어라 원문이 곧 기대값이다 (계획서).
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AccountSettingsPage(),
      ),
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
    expect(find.textContaining('작성한 게시물 14개와 사진'), findsOneWidget);
    expect(find.textContaining('남긴 댓글 37개'), findsOneWidget);
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

  testWidgets('개수 조회에 실패해도 종류만 적은 확인으로 탈퇴할 수 있다', (tester) async {
    when(
      accountUseCase.myContentSummary,
    ).thenAnswer((_) async => const Err(Failure.network()));
    when(() => useCase.deleteAccount()).thenAnswer((_) async => const Ok(null));

    await pumpPage(tester);
    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();

    expect(find.textContaining('작성한 게시물과 사진'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '탈퇴'));
    await tester.pumpAndSettle();
    verify(() => useCase.deleteAccount()).called(1);
  });

  testWidgets('개수를 기다리는 동안 다시 눌러도 확인은 한 번만 열린다', (tester) async {
    // 조회가 끝나기 전 상태를 붙잡아 둔다.
    final pending = Completer<Result<AccountContentSummary>>();
    when(accountUseCase.myContentSummary).thenAnswer((_) => pending.future);

    await pumpPage(tester);
    await tester.tap(find.text('회원 탈퇴'));
    await tester.pump();
    // 행이 잠겨 있으므로 두 번째 탭은 아무 일도 하지 않는다.
    await tester.tap(find.text('회원 탈퇴'));
    await tester.pump();

    pending.complete(
      const Ok(AccountContentSummary(postCount: 14, commentCount: 37)),
    );
    await tester.pumpAndSettle();

    expect(find.text('정말 탈퇴할까요?'), findsOneWidget);
    verify(accountUseCase.myContentSummary).called(1);
  });
}
