import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/auth/presentation/cubit/sign_up_cubit.dart';
import 'package:daylog/features/auth/presentation/cubit/sign_up_state.dart';
import 'package:daylog/features/auth/presentation/page/sign_up_page.dart';
import 'package:l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignUpCubit extends MockCubit<SignUpState> implements SignUpCubit {}

void main() {
  late _MockSignUpCubit cubit;

  setUp(() {
    cubit = _MockSignUpCubit();
    whenListen(
      cubit,
      const Stream<SignUpState>.empty(),
      initialState: const SignUpState(),
    );
    getIt.registerFactory<SignUpCubit>(() => cubit);
  });

  tearDown(getIt.reset);

  /// 사전 확인 결과가 이미 그려진 화면을 만든다.
  void withNicknameCheck(NicknameCheck check) => whenListen(
    cubit,
    const Stream<SignUpState>.empty(),
    initialState: SignUpState(nicknameCheck: check),
  );

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SignUpPage(),
      ),
    );
    await tester.pump();
  }

  // key 는 AuthTextField 에 붙어 있으므로 그 안의 TextFormField 까지 내려간다.
  String nicknameText(WidgetTester tester) => tester
      .widget<TextFormField>(
        find.descendant(
          of: find.byKey(const Key('signUp.nickname')),
          matching: find.byType(TextFormField),
        ),
      )
      .controller!
      .text;

  testWidgets('가입 폼은 자동 완성 그룹 안에 있다', (tester) async {
    await pumpPage(tester);
    expect(find.byType(AutofillGroup), findsOneWidget);
  });

  testWidgets('이메일에서 벗어나면 로컬 파트를 닉네임 제안값으로 채운다', (tester) async {
    await pumpPage(tester);

    await tester.enterText(
      find.byKey(const Key('signUp.email')),
      'karma951221@example.test',
    );
    await tester.tap(find.byKey(const Key('signUp.nickname')));
    await tester.pump();

    expect(nicknameText(tester), 'karma951221');
  });

  testWidgets('사용자가 닉네임을 이미 적었으면 덮어쓰지 않는다', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('signUp.nickname')), '내이름');
    await tester.enterText(
      find.byKey(const Key('signUp.email')),
      'karma951221@example.test',
    );
    await tester.tap(find.byKey(const Key('signUp.password')));
    await tester.pump();

    expect(nicknameText(tester), '내이름');
  });

  testWidgets('닉네임을 지운 뒤에는 다시 제안하지 않는다', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('signUp.nickname')), '내이름');
    await tester.enterText(find.byKey(const Key('signUp.nickname')), '');
    await tester.enterText(
      find.byKey(const Key('signUp.email')),
      'karma951221@example.test',
    );
    await tester.tap(find.byKey(const Key('signUp.password')));
    await tester.pump();

    expect(nicknameText(tester), '');
  });

  testWidgets('규칙에 맞지 않는 로컬 파트는 제안하지 않는다', (tester) async {
    await pumpPage(tester);

    // 1자 — 닉네임 최소 길이(2) 미만.
    await tester.enterText(
      find.byKey(const Key('signUp.email')),
      'a@example.test',
    );
    await tester.tap(find.byKey(const Key('signUp.nickname')));
    await tester.pump();

    expect(nicknameText(tester), '');
  });

  testWidgets('제안값은 최대 길이로 잘라 넣는다', (tester) async {
    await pumpPage(tester);

    await tester.enterText(
      find.byKey(const Key('signUp.email')),
      'abcdefghijklmnopqrstuvwxyz@example.test',
    );
    await tester.tap(find.byKey(const Key('signUp.nickname')));
    await tester.pump();

    expect(nicknameText(tester), 'abcdefghijklmnopqrst');
  });

  testWidgets('형식이 어긋난 이메일에서는 제안하지 않는다', (tester) async {
    await pumpPage(tester);

    await tester.enterText(
      find.byKey(const Key('signUp.email')),
      'jo hn@example.test',
    );
    await tester.tap(find.byKey(const Key('signUp.nickname')));
    await tester.pump();

    expect(nicknameText(tester), '');
  });

  testWidgets('닉네임을 입력하면 사전 확인을 요청한다', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('signUp.nickname')), '새이름');
    await tester.pump();

    verify(() => cubit.checkNickname('새이름')).called(1);
  });

  testWidgets('제안값도 그대로 사전 확인한다', (tester) async {
    await pumpPage(tester);

    await tester.enterText(
      find.byKey(const Key('signUp.email')),
      'karma951221@example.test',
    );
    await tester.tap(find.byKey(const Key('signUp.nickname')));
    await tester.pump();

    verify(() => cubit.checkNickname('karma951221')).called(1);
  });

  testWidgets('확인 중에는 입력칸에 진행 표시가 돈다', (tester) async {
    withNicknameCheck(const NicknameCheck.checking());
    await pumpPage(tester);

    expect(find.text('확인 중…'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('signUp.nickname')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
  });

  testWidgets('쓸 수 있는 닉네임은 가입을 누르기 전에 알려준다', (tester) async {
    withNicknameCheck(const NicknameCheck.available());
    await pumpPage(tester);

    expect(find.text('사용할 수 있는 닉네임입니다'), findsOneWidget);
  });

  testWidgets('이미 쓰이는 닉네임도 가입을 누르기 전에 알려준다', (tester) async {
    withNicknameCheck(const NicknameCheck.taken());
    await pumpPage(tester);

    expect(find.text('이미 사용 중인 닉네임입니다'), findsOneWidget);
  });
}
