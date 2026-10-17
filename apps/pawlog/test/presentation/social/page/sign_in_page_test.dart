import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/presentation/social/cubit/auth_cubit.dart';
import 'package:pawlog/presentation/social/page/sign_in_page.dart';

import '../../../support/mock_social_use_case.dart';
import '../../../support/pump_app.dart';

void main() {
  late MockSocialUseCase useCase;
  late int signedIn;

  setUp(() {
    useCase = MockSocialUseCase();
    signedIn = 0;
    getIt.registerFactory<AuthCubit>(() => AuthCubit(useCase));
  });
  tearDown(getIt.reset);

  Future<void> pump(WidgetTester tester) =>
      pumpApp(tester, SignInPage(onSignedIn: () => signedIn++));

  Future<void> fill(
    WidgetTester tester, {
    String email = 'a@b.com',
    String password = 'password1',
    String? nickname,
  }) async {
    await tester.enterText(find.byKey(const Key('sign-in-email')), email);
    await tester.enterText(find.byKey(const Key('sign-in-password')), password);
    if (nickname != null) {
      await tester.enterText(
        find.byKey(const Key('sign-in-nickname')),
        nickname,
      );
    }
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();
  }

  /// 성공하면 화면은 떠날 때까지 진행 표시를 돌린다 — settle 하지 않고 한 박자만 민다.
  Future<void> submitAndLeave(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pump();
    await tester.pump();
  }

  Future<void> switchMode(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('sign-in-switch')));
    await tester.pumpAndSettle();
  }

  testWidgets('로그인 모드는 이메일 · 비밀번호만 보이고 안내 문구가 있다', (tester) async {
    await pump(tester);

    expect(find.byKey(const Key('sign-in-email')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-password')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-nickname')), findsNothing);
    expect(find.text('로그인하면 공유하고 좋아요를 누를 수 있어요'), findsOneWidget);
    expect(find.text('처음이면 가입하기'), findsOneWidget);
  });

  testWidgets('전환 버튼을 누르면 가입 모드가 되어 닉네임 칸이 생긴다', (tester) async {
    await pump(tester);

    await switchMode(tester);

    expect(find.byKey(const Key('sign-in-nickname')), findsOneWidget);
    expect(find.text('이미 계정이 있으면 로그인'), findsOneWidget);

    await switchMode(tester);

    expect(find.byKey(const Key('sign-in-nickname')), findsNothing);
  });

  testWidgets('닉네임이 2자 미만이면 입력칸 아래에 알리고 보내지 않는다', (tester) async {
    await pump(tester);
    await switchMode(tester);

    await fill(tester, nickname: 'a');
    await submit(tester);

    expect(find.text('닉네임은 2자 이상이어야 합니다'), findsOneWidget);
    verifyNever(() => useCase.signUp(any(), any(), any()));
  });

  testWidgets('닉네임이 20자를 넘으면 알린다', (tester) async {
    await pump(tester);
    await switchMode(tester);

    await fill(tester, nickname: 'a' * 21);
    await submit(tester);

    expect(find.text('닉네임은 20자 이하여야 합니다'), findsOneWidget);
  });

  testWidgets('이메일 형식이 틀리면 보내지 않는다', (tester) async {
    await pump(tester);

    await fill(tester, email: 'nope');
    await submit(tester);

    expect(find.text('이메일 형식이 올바르지 않습니다'), findsOneWidget);
    verifyNever(() => useCase.signIn(any(), any()));
  });

  testWidgets('로그인에 성공하면 onSignedIn 을 부른다', (tester) async {
    when(
      () => useCase.signIn('a@b.com', 'password1'),
    ).thenAnswer((_) async => const Ok(null));
    await pump(tester);

    await fill(tester);
    await submitAndLeave(tester);

    expect(signedIn, 1);
  });

  testWidgets('가입에 성공하면 닉네임을 넘기고 onSignedIn 을 부른다', (tester) async {
    when(
      () => useCase.signUp('a@b.com', 'password1', '콩이네'),
    ).thenAnswer((_) async => const Ok(null));
    await pump(tester);
    await switchMode(tester);

    await fill(tester, nickname: '콩이네');
    await submitAndLeave(tester);

    expect(signedIn, 1);
  });

  testWidgets('자격이 틀리면 스낵바로 알린다', (tester) async {
    when(() => useCase.signIn(any(), any())).thenAnswer(
      (_) async =>
          const Err(Failure.auth(failureCode: FailureCode.invalidCredentials)),
    );
    await pump(tester);

    await fill(tester);
    await submit(tester);

    expect(find.text('로그인하지 못했어요. 이메일과 비밀번호를 확인해 주세요'), findsOneWidget);
    expect(signedIn, 0);
  });

  testWidgets('닉네임이 겹치면 닉네임 칸 아래에 알린다', (tester) async {
    when(() => useCase.signUp(any(), any(), any())).thenAnswer(
      (_) async => const Err(
        Failure.validation(
          field: 'nickname',
          failureCode: FailureCode.nicknameTaken,
        ),
      ),
    );
    await pump(tester);
    await switchMode(tester);

    await fill(tester, nickname: '콩이네');
    await submit(tester);

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('sign-in-nickname')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.decoration?.errorText, '이미 쓰는 닉네임이에요');
    expect(signedIn, 0);
  });
}
