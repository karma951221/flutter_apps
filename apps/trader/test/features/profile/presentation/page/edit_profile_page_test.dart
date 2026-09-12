import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/app/router/routes.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:daylog/features/auth/domain/entity/app_user.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_event.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_state.dart';
import 'package:daylog/features/profile/domain/entity/profile.dart';
import 'package:daylog/features/profile/domain/entity/profile_update.dart';
import 'package:daylog/features/profile/domain/usecase/profile_use_case.dart';
import 'package:daylog/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:daylog/features/profile/presentation/page/edit_profile_page.dart';
import 'package:l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileUseCase extends Mock implements ProfileUseCase {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

const _me = AppUser(id: 'me', email: 'me@example.test', nickname: '카르마');

final _profile = Profile(
  id: 'me',
  nickname: '카르마',
  createdAt: DateTime.utc(2026, 8, 22, 9),
  updatedAt: DateTime.utc(2026, 8, 22, 9),
);

void main() {
  setUpAll(() => registerFallbackValue(const ProfileUpdate(nickname: '')));

  late _MockProfileUseCase useCase;
  late _MockAuthBloc authBloc;

  setUp(() {
    useCase = _MockProfileUseCase();
    authBloc = _MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(_me),
    );
    when(useCase.getMyProfile).thenAnswer((_) async => Ok(_profile));

    getIt.registerFactory<ProfileCubit>(() => ProfileCubit(useCase));
  });

  tearDown(getIt.reset);

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const EditProfilePage(),
        ),
      ),
    );
    await tester.pump();
  }

  /// setup 모드는 저장·건너뛰기 뒤 홈으로 `go` 하므로 라우터가 필요하다.
  Future<GoRouter> pumpSetup(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: Routes.profileSetup,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('홈')),
        ),
        GoRoute(
          path: Routes.profileSetup,
          builder: (_, _) => const EditProfilePage(isSetup: true),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) =>
            BlocProvider<AuthBloc>.value(value: authBloc, child: child!),
      ),
    );
    await tester.pump();
    return router;
  }

  /// 디바운스가 지나 조회 결과가 화면에 닿을 때까지 민다.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(
      nicknameCheckDebounce + const Duration(milliseconds: 100),
    );
    await tester.pump();
  }

  testWidgets('닉네임을 바꾸면 사용 가능 여부를 미리 알려준다', (tester) async {
    when(
      () => useCase.isNicknameAvailable(any()),
    ).thenAnswer((_) async => const Ok(true));

    await pumpPage(tester);
    await tester.enterText(find.byType(TextFormField).first, '새이름');
    await settle(tester);

    expect(find.text('사용할 수 있는 닉네임입니다'), findsOneWidget);
    verify(() => useCase.isNicknameAvailable('새이름')).called(1);
  });

  testWidgets('이미 쓰이는 닉네임은 저장하기 전에 알려준다', (tester) async {
    when(
      () => useCase.isNicknameAvailable(any()),
    ).thenAnswer((_) async => const Ok(false));

    await pumpPage(tester);
    await tester.enterText(find.byType(TextFormField).first, '겹치는이름');
    await settle(tester);

    expect(find.text('이미 사용 중인 닉네임입니다'), findsOneWidget);
  });

  testWidgets('지금 쓰고 있는 닉네임은 확인하지 않는다', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextFormField).first, '카르마');
    await settle(tester);

    expect(find.text('사용할 수 있는 닉네임입니다'), findsNothing);
    expect(find.text('이미 사용 중인 닉네임입니다'), findsNothing);
    verifyNever(() => useCase.isNicknameAvailable(any()));
  });

  testWidgets('프로필 꾸미기 모드는 제목·안내·나중에·계속을 보여주고 뒤로가기가 없다', (tester) async {
    await pumpSetup(tester);

    expect(find.text('프로필 꾸미기'), findsOneWidget);
    expect(find.textContaining('이웃에게 나를 알려보세요'), findsOneWidget);
    expect(find.text('나중에'), findsOneWidget);
    expect(find.text('계속'), findsOneWidget);
    expect(find.text('저장'), findsNothing);
    expect(find.byType(BackButton), findsNothing);
    // 나중에는 계속 아래의 텍스트 버튼이다 (AppBar 가 아니다).
    expect(find.widgetWithText(TextButton, '나중에'), findsOneWidget);
  });

  testWidgets('나중에를 누르면 저장 없이 홈으로 간다', (tester) async {
    final router = await pumpSetup(tester);

    await tester.tap(find.text('나중에'));
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, Routes.home);
    verifyNever(
      () => useCase.updateMyProfile(any(), newAvatar: any(named: 'newAvatar')),
    );
  });

  testWidgets('프로필 꾸미기에서 조회가 실패해도 다시 시도와 나중에가 남는다', (tester) async {
    when(
      useCase.getMyProfile,
    ).thenAnswer((_) async => const Err(Failure.network()));
    final router = await pumpSetup(tester);
    await tester.pumpAndSettle();

    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.text('나중에'), findsOneWidget);

    await tester.tap(find.text('나중에'));
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, Routes.home);
  });

  testWidgets('프로필 꾸미기에서 시스템 뒤로가기는 앱을 닫지 않고 홈으로 간다', (tester) async {
    final router = await pumpSetup(tester);
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, Routes.home);
  });

  testWidgets('계속을 누르면 저장한 뒤 홈으로 간다', (tester) async {
    when(
      () => useCase.updateMyProfile(any(), newAvatar: any(named: 'newAvatar')),
    ).thenAnswer((_) async => Ok(_profile));
    final router = await pumpSetup(tester);

    await tester.enterText(find.byType(TextFormField).last, '오늘도 기록');
    await tester.tap(find.text('계속'));
    await tester.pumpAndSettle();

    verify(
      () => useCase.updateMyProfile(any(), newAvatar: any(named: 'newAvatar')),
    ).called(1);
    expect(router.state.matchedLocation, Routes.home);
  });

  testWidgets('저장 중 시스템 뒤로가기는 화면을 지키고, 저장이 끝난 뒤 홈으로 간다', (tester) async {
    final response = Completer<Result<Profile>>();
    when(
      () => useCase.updateMyProfile(any(), newAvatar: any(named: 'newAvatar')),
    ).thenAnswer((_) => response.future);
    final router = await pumpSetup(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('계속'));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();

    // 저장 중에는 떠나지 않는다. 떠나면 결과를 알려줄 곳이 사라진다.
    expect(find.text('홈'), findsNothing);
    expect(router.state.matchedLocation, Routes.profileSetup);

    response.complete(Ok(_profile));
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, Routes.home);
    expect(tester.takeException(), isNull);
  });

  testWidgets('조회 중 시스템 뒤로가기는 홈으로 가고, 늦게 온 결과는 아무 일도 하지 않는다', (tester) async {
    final response = Completer<Result<Profile>>();
    when(useCase.getMyProfile).thenAnswer((_) => response.future);
    final router = await pumpSetup(tester);
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, Routes.home);

    // 화면이 닫힌 뒤 도착한 조회 결과가 예외가 되면 안 된다.
    response.complete(Ok(_profile));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
