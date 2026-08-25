import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/design_system/widget/app_list_tile.dart';
import 'package:daylog/features/auth/domain/entity/app_user.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_event.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_state.dart';
import 'package:daylog/features/settings/presentation/page/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

const _me = AppUser(
  id: 'me',
  email: 'me@example.test',
  nickname: '카르마',
  bio: '기록하는 사람',
);

void main() {
  late _MockAuthBloc authBloc;

  setUp(() {
    authBloc = _MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(_me),
    );
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const SettingsPage(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('설정 목록은 프로필 편집 · 계정 설정 · 차단한 사용자 · 로그아웃 네 항목을 보여준다', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('설정'), findsOneWidget);
    expect(find.byType(AppListTile), findsNWidgets(4));
    expect(find.text('프로필 편집'), findsOneWidget);
    expect(find.text('계정 설정'), findsOneWidget);
    expect(find.text('차단한 사용자'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
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
    expect(find.byType(AppListTile), findsNWidgets(4));
  });
}
