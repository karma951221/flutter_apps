import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/design_system/widget/app_list_tile.dart';
import 'package:daylog/features/auth/domain/entity/app_user.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_event.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_state.dart';
import 'package:daylog/features/settings/presentation/page/settings_page.dart';
import 'package:daylog/features/theme/domain/entity/app_theme_mode.dart';
import 'package:daylog/features/theme/domain/usecase/theme_use_case.dart';
import 'package:daylog/features/theme/presentation/cubit/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockThemeUseCase extends Mock implements ThemeUseCase {}

const _me = AppUser(
  id: 'me',
  email: 'me@example.test',
  nickname: '카르마',
  bio: '기록하는 사람',
);

void main() {
  late _MockAuthBloc authBloc;
  late _MockThemeUseCase themeUseCase;
  late ThemeCubit themeCubit;

  setUpAll(() {
    registerFallbackValue(AppThemeMode.system);
  });

  setUp(() {
    authBloc = _MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(_me),
    );
    themeUseCase = _MockThemeUseCase();
    when(themeUseCase.loadThemeMode).thenReturn(AppThemeMode.system);
    when(() => themeUseCase.saveThemeMode(any())).thenAnswer((_) async {});
    themeCubit = ThemeCubit(themeUseCase);
    addTearDown(themeCubit.close);
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ThemeCubit>.value(value: themeCubit),
          ],
          child: const SettingsPage(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('설정 목록은 프로필 편집 · 계정 설정 · 화면 테마 · 차단한 사용자 · 로그아웃 다섯 항목을 보여준다', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('설정'), findsOneWidget);
    expect(find.byType(AppListTile), findsNWidgets(5));
    expect(find.text('프로필 편집'), findsOneWidget);
    expect(find.text('계정 설정'), findsOneWidget);
    expect(find.text('화면 테마'), findsOneWidget);
    expect(find.text('차단한 사용자'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
  });

  testWidgets('화면 테마 행은 현재 모드를 subtitle 로 보여준다', (tester) async {
    when(themeUseCase.loadThemeMode).thenReturn(AppThemeMode.dark);
    themeCubit = ThemeCubit(themeUseCase);
    addTearDown(themeCubit.close);

    await pumpPage(tester);

    expect(find.text('다크'), findsOneWidget);
  });

  testWidgets('화면 테마를 탭하면 세 가지 선택지가 나오고, 고르면 즉시 적용되고 닫힌다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('화면 테마'));
    await tester.pumpAndSettle();

    expect(find.byType(RadioListTile<AppThemeMode>), findsNWidgets(3));
    expect(find.text('시스템 설정'), findsNWidgets(2)); // 행의 subtitle + 다이얼로그
    expect(find.text('라이트'), findsOneWidget);
    expect(find.text('다크'), findsOneWidget);

    await tester.tap(find.text('다크'));
    await tester.pumpAndSettle();

    expect(themeCubit.state, AppThemeMode.dark);
    verify(() => themeUseCase.saveThemeMode(AppThemeMode.dark)).called(1);
    // 고르면 다이얼로그가 닫히고 행의 subtitle 이 새 값을 보여준다.
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('다크'), findsOneWidget);
  });

  testWidgets('다이얼로그를 그냥 닫으면 테마가 그대로다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('화면 테마'));
    await tester.pumpAndSettle();

    // 바깥 탭 = 취소. 취소 버튼을 두지 않은 이유다.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(themeCubit.state, AppThemeMode.system);
    verifyNever(() => themeUseCase.saveThemeMode(any()));
  });

  testWidgets('상단 요약은 세션의 닉네임과 이메일을 그대로 보여준다', (tester) async {
    await pumpPage(tester);

    expect(find.text('카르마'), findsOneWidget);
    expect(find.text('me@example.test'), findsOneWidget);
  });

  testWidgets('로그아웃은 확인 다이얼로그를 거쳐야 요청된다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    expect(find.text('로그아웃할까요?'), findsOneWidget);
    // 다이얼로그를 띄운 것만으로는 세션을 정리하지 않는다.
    verifyNever(() => authBloc.add(const AuthEvent.signOutRequested()));

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    verifyNever(() => authBloc.add(const AuthEvent.signOutRequested()));

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '로그아웃'));
    await tester.pumpAndSettle();

    verify(() => authBloc.add(const AuthEvent.signOutRequested())).called(1);
  });

  testWidgets('세션이 없으면 요약을 그리지 않고 목록만 남는다', (tester) async {
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );

    await pumpPage(tester);

    expect(find.text('카르마'), findsNothing);
    expect(find.byType(AppListTile), findsNWidgets(5));
  });
}
