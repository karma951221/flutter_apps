import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:daylog/features/auth/presentation/cubit/submit_state.dart';
import 'package:daylog/features/auth/presentation/page/sign_in_page.dart';
import 'package:daylog/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignInCubit extends MockCubit<SubmitState> implements SignInCubit {}

void main() {
  late _MockSignInCubit cubit;

  setUp(() {
    cubit = _MockSignInCubit();
    whenListen(
      cubit,
      const Stream<SubmitState>.empty(),
      initialState: const SubmitState.idle(),
    );
    getIt.registerFactory<SignInCubit>(() => cubit);
  });

  tearDown(getIt.reset);

  Future<void> pumpPage(
    WidgetTester tester, {
    Locale locale = const Locale('ko'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        // ko 가 ARB template 언어라 원문이 곧 기대값이다 (계획서).
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SignInPage(),
      ),
    );
    await tester.pump();
  }

  testWidgets('앱 이름과 한 줄 설명이 화면 위에 선다', (tester) async {
    await pumpPage(tester);

    expect(find.text('daylog'), findsOneWidget);
    expect(find.text('오늘 하루를 기록하고 이웃과 나눠보세요.'), findsOneWidget);
    expect(find.text('먼저 둘러보기'), findsOneWidget);
  });

  testWidgets('빈 폼은 제출하지 않고 필드별 오류를 보여준다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pump();

    verifyNever(
      () => cubit.submit(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
    // 이메일·비밀번호 두 칸 모두 자기 자리에서 오류를 말한다.
    expect(find.textContaining('이메일'), findsWidgets);
  });

  testWidgets('영어 화면의 폼 검증 오류도 영어로 보인다', (tester) async {
    await pumpPage(tester, locale: const Locale('en'));

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('입력을 채우면 그대로 cubit 에 넘긴다', (tester) async {
    when(
      () => cubit.submit(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});

    await pumpPage(tester);

    await tester.enterText(
      find.byKey(const Key('signIn.email')),
      'me@test.com',
    );
    await tester.enterText(
      find.byKey(const Key('signIn.password')),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pump();

    verify(
      () => cubit.submit(email: 'me@test.com', password: 'password123'),
    ).called(1);
  });

  testWidgets('진행 중에는 버튼이 로딩으로 바뀌고 다른 진입도 막힌다', (tester) async {
    whenListen(
      cubit,
      const Stream<SubmitState>.empty(),
      initialState: const SubmitState.inProgress(),
    );

    await pumpPage(tester);

    expect(find.text('로그인'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // 진행 중에 회원가입으로 새 나가면 요청 결과를 받을 화면이 사라진다.
    final signUp = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '회원가입'),
    );
    expect(signUp.onPressed, isNull);
  });

  testWidgets('실패는 입력 아래에 문구로 남는다', (tester) async {
    whenListen(
      cubit,
      const Stream<SubmitState>.empty(),
      initialState: const SubmitState.failure(
        Failure.auth(message: '이메일 또는 비밀번호가 올바르지 않습니다'),
      ),
    );

    await pumpPage(tester);

    expect(find.text('이메일 또는 비밀번호가 올바르지 않습니다'), findsOneWidget);
  });
}
