import 'dart:async';

import 'package:daylog/core/di/injection.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/auth/domain/usecase/auth_use_case.dart';
import 'package:daylog/features/auth/presentation/widget/auth_text_field.dart';
import 'package:daylog/features/settings/presentation/cubit/change_password_cubit.dart';
import 'package:daylog/features/settings/presentation/page/change_password_page.dart';
import 'package:daylog/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthUseCase extends Mock implements AuthUseCase {}

void main() {
  late _MockAuthUseCase useCase;
  final navigatorKey = GlobalKey<NavigatorState>();

  setUp(() {
    useCase = _MockAuthUseCase();
    getIt.registerFactory<ChangePasswordCubit>(
      () => ChangePasswordCubit(useCase),
    );
  });

  tearDown(getIt.reset);

  /// 돌아갈 화면이 있어야 성공 후 pop 을 확인할 수 있다.
  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        theme: AppTheme.light(),
        // ko 가 ARB template 언어라 원문이 곧 기대값이다 (계획서).
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Center(child: Text('이전 화면'))),
      ),
    );
    unawaited(
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const ChangePasswordPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fill(
    WidgetTester tester, {
    required String password,
    required String confirm,
  }) async {
    await tester.enterText(find.byType(AuthTextField).at(0), password);
    await tester.enterText(find.byType(AuthTextField).at(1), confirm);
    await tester.pump();
  }

  testWidgets('두 칸이 다르면 저장을 시도하지 않는다', (tester) async {
    await pumpPage(tester);
    await fill(tester, password: 'password123', confirm: 'password124');

    await tester.tap(find.widgetWithText(FilledButton, '변경'));
    await tester.pumpAndSettle();

    expect(find.text('비밀번호가 일치하지 않습니다'), findsOneWidget);
    verifyNever(() => useCase.updatePassword(any()));
  });

  testWidgets('짧은 비밀번호는 저장을 시도하지 않는다', (tester) async {
    await pumpPage(tester);
    await fill(tester, password: 'short', confirm: 'short');

    await tester.tap(find.widgetWithText(FilledButton, '변경'));
    await tester.pumpAndSettle();

    verifyNever(() => useCase.updatePassword(any()));
  });

  testWidgets('성공하면 Snackbar 로 알리고 이전 화면으로 돌아간다', (tester) async {
    when(
      () => useCase.updatePassword(any()),
    ).thenAnswer((_) async => const Ok(null));

    await pumpPage(tester);
    await fill(tester, password: 'password123', confirm: 'password123');

    await tester.tap(find.widgetWithText(FilledButton, '변경'));
    await tester.pumpAndSettle();

    verify(() => useCase.updatePassword('password123')).called(1);
    expect(find.text('비밀번호를 변경했습니다'), findsOneWidget);
    expect(find.byType(ChangePasswordPage), findsNothing);
    expect(find.text('이전 화면'), findsOneWidget);
  });

  testWidgets('실패하면 화면에 남고 오류를 Snackbar 로 알린다', (tester) async {
    when(
      () => useCase.updatePassword(any()),
    ).thenAnswer((_) async => const Err(Failure.auth(message: '세션이 만료되었습니다')));

    await pumpPage(tester);
    await fill(tester, password: 'password123', confirm: 'password123');

    await tester.tap(find.widgetWithText(FilledButton, '변경'));
    await tester.pumpAndSettle();

    expect(find.text('세션이 만료되었습니다'), findsOneWidget);
    expect(find.byType(ChangePasswordPage), findsOneWidget);
  });
}
