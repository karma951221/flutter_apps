import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/core/di/injection.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/auth/domain/entity/app_user.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_event.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_state.dart';
import 'package:daylog/features/chat/domain/chat_policy.dart';
import 'package:daylog/features/chat/domain/entity/chat_room.dart';
import 'package:daylog/features/chat/domain/usecase/chat_use_case.dart';
import 'package:daylog/features/chat/presentation/cubit/create_room_cubit.dart';
import 'package:daylog/features/chat/presentation/page/create_room_page.dart';
import 'package:daylog/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatUseCase extends Mock implements ChatUseCase {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

const _me = AppUser(id: 'me', email: 'me@example.test', nickname: '카르마');

void main() {
  late _MockChatUseCase useCase;
  late _MockAuthBloc authBloc;

  setUp(() {
    useCase = _MockChatUseCase();
    authBloc = _MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(_me),
    );
    when(
      () => useCase.createRoom(
        title: any(named: 'title'),
        description: any(named: 'description'),
        memberLimit: any(named: 'memberLimit'),
      ),
    ).thenAnswer(
      (_) async => Ok(
        ChatRoom(id: 'r1', title: '새 방', createdAt: DateTime.utc(2026, 8, 28)),
      ),
    );
    when(
      () => useCase.joinRoom(
        roomId: any(named: 'roomId'),
        nickname: any(named: 'nickname'),
      ),
    ).thenAnswer((_) async => const Ok(null));

    getIt.registerFactory<CreateRoomCubit>(() => CreateRoomCubit(useCase));
  });

  tearDown(getIt.reset);

  /// 성공하면 화면이 pop 하고 방으로 push 하므로 라우터가 필요하다.
  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      // 목록에서 밀고 들어온 모양이어야 한다 — 성공하면 pop 뒤에 방으로
      // push 하기 때문이다.
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('목록')),
        ),
        GoRoute(
          path: '/chat/new',
          builder: (_, _) => BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const CreateRoomPage(),
          ),
        ),
        GoRoute(
          path: '/chat/:roomId',
          builder: (_, state) => Text('room:${state.pathParameters['roomId']}'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    router.push('/chat/new');
    await tester.pumpAndSettle();
  }

  testWidgets('방 이름 · 소개 · 방에서 쓸 이름 · 정원을 받는다', (tester) async {
    await pumpPage(tester);

    // E2E 가 이 라벨로 화면 도착을 판정한다.
    expect(find.text('방 이름'), findsOneWidget);
    expect(find.text('소개 (선택)'), findsOneWidget);
    expect(find.text('방에서 쓸 이름'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('방에서 쓸 이름의 기본값은 내 프로필 닉네임이다', (tester) async {
    await pumpPage(tester);

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields.last.controller?.text, '카르마');
  });

  testWidgets('정원 기본값을 라벨에 보여준다', (tester) async {
    await pumpPage(tester);

    expect(find.text('정원 ${ChatPolicy.memberLimitDefault}명'), findsOneWidget);
  });

  testWidgets('만들기를 누르면 개설과 입장을 함께 요청한다', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('createRoom.title')), '새 방');
    await tester.tap(find.byKey(const Key('createRoom.submit')));
    await tester.pumpAndSettle();

    verify(
      () => useCase.createRoom(
        title: '새 방',
        description: '',
        memberLimit: ChatPolicy.memberLimitDefault,
      ),
    ).called(1);
    // 만든 사람도 참여자다 — 방별 닉네임이 있어야 한다.
    verify(() => useCase.joinRoom(roomId: 'r1', nickname: '카르마')).called(1);
    // 만든 방으로 곧바로 들어간다.
    expect(find.text('room:r1'), findsOneWidget);
  });

  testWidgets('개설에 실패하면 Snackbar 로 알리고 화면에 남는다', (tester) async {
    when(
      () => useCase.createRoom(
        title: any(named: 'title'),
        description: any(named: 'description'),
        memberLimit: any(named: 'memberLimit'),
      ),
    ).thenAnswer(
      (_) async => const Err(Failure.validation(message: '방 이름을 입력하세요')),
    );

    await pumpPage(tester);
    await tester.tap(find.byKey(const Key('createRoom.submit')));
    await tester.pump();
    await tester.pump();

    expect(find.text('방 이름을 입력하세요'), findsOneWidget);
    verifyNever(
      () => useCase.joinRoom(
        roomId: any(named: 'roomId'),
        nickname: any(named: 'nickname'),
      ),
    );
  });
}
