import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:daylog/features/preferences/domain/entity/app_language.dart';
import 'package:daylog/features/preferences/domain/entity/app_theme_mode.dart';
import 'package:daylog/features/preferences/domain/usecase/preferences_use_case.dart';
import 'package:daylog/features/preferences/presentation/cubit/language_cubit.dart';
import 'package:daylog/features/preferences/presentation/cubit/theme_cubit.dart';
import 'package:daylog/features/settings/presentation/page/settings_page.dart';
import 'package:l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockPreferencesUseCase extends Mock implements PreferencesUseCase {}

const _me = AppUser(
  id: 'me',
  email: 'me@example.test',
  nickname: '카르마',
  bio: '기록하는 사람',
);

void main() {
  late _MockAuthBloc authBloc;
  late _MockPreferencesUseCase preferencesUseCase;
  late ThemeCubit themeCubit;
  late LanguageCubit languageCubit;

  setUpAll(() {
    registerFallbackValue(AppThemeMode.system);
    registerFallbackValue(AppLanguage.system);
  });

  setUp(() {
    authBloc = _MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(_me),
    );
    preferencesUseCase = _MockPreferencesUseCase();
    when(preferencesUseCase.loadThemeMode).thenReturn(AppThemeMode.system);
    when(
      () => preferencesUseCase.saveThemeMode(any()),
    ).thenAnswer((_) async {});
    when(preferencesUseCase.loadLanguage).thenReturn(AppLanguage.system);
    when(() => preferencesUseCase.saveLanguage(any())).thenAnswer((_) async {});
    themeCubit = ThemeCubit(preferencesUseCase);
    addTearDown(themeCubit.close);
    languageCubit = LanguageCubit(preferencesUseCase);
    addTearDown(languageCubit.close);
  });

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
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ThemeCubit>.value(value: themeCubit),
            BlocProvider<LanguageCubit>.value(value: languageCubit),
          ],
          child: const SettingsPage(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    '설정 목록은 프로필 편집 · 계정 설정 · 화면 테마 · 언어 · 차단한 사용자 · 로그아웃 여섯 항목을 보여준다',
    (tester) async {
      await pumpPage(tester);

      expect(find.text('설정'), findsOneWidget);
      expect(find.byType(AppListTile), findsNWidgets(6));
      expect(find.text('프로필 편집'), findsOneWidget);
      expect(find.text('계정 설정'), findsOneWidget);
      expect(find.text('화면 테마'), findsOneWidget);
      expect(find.text('언어'), findsOneWidget);
      expect(find.text('차단한 사용자'), findsOneWidget);
      expect(find.text('로그아웃'), findsOneWidget);
    },
  );

  testWidgets('언어 행은 화면 테마 바로 아래다', (tester) async {
    await pumpPage(tester);

    final tiles = tester.widgetList<AppListTile>(find.byType(AppListTile));
    final titles = tiles.map((tile) => (tile.title as Text).data).toList();
    expect(titles.indexOf('언어'), titles.indexOf('화면 테마') + 1);
  });

  testWidgets('en 으로 뜨면 설정 화면이 영어다', (tester) async {
    // 세 언어 × 전 화면 매트릭스 대신 대표 화면 스모크만 둔다 (계획서).
    await pumpPage(tester, locale: const Locale('en'));

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('ja 로 뜨면 설정 화면이 일본어다', (tester) async {
    await pumpPage(tester, locale: const Locale('ja'));

    expect(find.text('設定'), findsOneWidget);
    expect(find.text('言語'), findsOneWidget);
    expect(find.text('ログアウト'), findsOneWidget);
  });

  testWidgets('화면 테마 행은 현재 모드를 subtitle 로 보여준다', (tester) async {
    when(preferencesUseCase.loadThemeMode).thenReturn(AppThemeMode.dark);
    themeCubit = ThemeCubit(preferencesUseCase);
    addTearDown(themeCubit.close);

    await pumpPage(tester);

    expect(find.text('다크'), findsOneWidget);
  });

  testWidgets('화면 테마를 탭하면 세 가지 선택지가 나오고, 고르면 즉시 적용되고 닫힌다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('화면 테마'));
    await tester.pumpAndSettle();

    expect(find.byType(RadioListTile<AppThemeMode>), findsNWidgets(3));
    // 테마·언어 두 행의 subtitle + 다이얼로그의 선택지.
    expect(find.text('시스템 설정'), findsNWidgets(3));
    expect(find.text('라이트'), findsOneWidget);
    expect(find.text('다크'), findsOneWidget);

    await tester.tap(find.text('다크'));
    await tester.pumpAndSettle();

    expect(themeCubit.state, AppThemeMode.dark);
    verify(() => preferencesUseCase.saveThemeMode(AppThemeMode.dark)).called(1);
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
    verifyNever(() => preferencesUseCase.saveThemeMode(any()));
  });

  testWidgets('언어 행은 현재 언어를 subtitle 로 보여준다', (tester) async {
    when(preferencesUseCase.loadLanguage).thenReturn(AppLanguage.japanese);
    languageCubit = LanguageCubit(preferencesUseCase);
    addTearDown(languageCubit.close);

    await pumpPage(tester);

    expect(find.text('日本語'), findsOneWidget);
  });

  testWidgets('언어를 탭하면 네 가지 선택지가 나오고, 고르면 즉시 적용되고 닫힌다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('언어'));
    await tester.pumpAndSettle();

    expect(find.byType(RadioListTile<AppLanguage>), findsNWidgets(4));
    // 언어 이름은 자기 표기로 고정이다 — 현재 언어를 따르는 건 '시스템 설정'뿐.
    expect(find.text('한국어'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('日本語'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(languageCubit.state, AppLanguage.english);
    verify(
      () => preferencesUseCase.saveLanguage(AppLanguage.english),
    ).called(1);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('언어 다이얼로그를 그냥 닫으면 언어가 그대로다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('언어'));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(languageCubit.state, AppLanguage.system);
    verifyNever(() => preferencesUseCase.saveLanguage(any()));
  });

  testWidgets('언어 이름은 화면 언어가 영어여도 자기 표기 그대로다', (tester) async {
    await pumpPage(tester, locale: const Locale('en'));

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    expect(find.text('한국어'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('日本語'), findsOneWidget);
    // '시스템'만 현재 언어를 따른다.
    expect(find.text('System default'), findsNWidgets(3));
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
    expect(find.byType(AppListTile), findsNWidgets(6));
  });
}
