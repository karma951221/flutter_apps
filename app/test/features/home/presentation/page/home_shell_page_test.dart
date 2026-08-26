import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/core/di/injection.dart';
import 'package:daylog/core/pagination/cursor_page.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/auth/domain/entity/app_user.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_event.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_state.dart';
import 'package:daylog/features/feed/domain/entity/feed_post.dart';
import 'package:daylog/features/feed/domain/usecase/feed_use_case.dart';
import 'package:daylog/features/feed/presentation/cubit/feed_cubit.dart';
import 'package:daylog/features/home/presentation/page/home_shell_page.dart';
import 'package:daylog/features/post/domain/usecase/post_use_case.dart';
import 'package:daylog/features/post/presentation/cubit/post_cubit.dart';
import 'package:daylog/features/profile/domain/entity/profile.dart';
import 'package:daylog/features/profile/domain/usecase/profile_use_case.dart';
import 'package:daylog/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:daylog/features/reaction/domain/usecase/reaction_use_case.dart';
import 'package:daylog/features/theme/domain/entity/app_theme_mode.dart';
import 'package:daylog/features/theme/domain/usecase/theme_use_case.dart';
import 'package:daylog/features/theme/presentation/cubit/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFeedUseCase extends Mock implements FeedUseCase {}

class _MockPostUseCase extends Mock implements PostUseCase {}

class _MockProfileUseCase extends Mock implements ProfileUseCase {}

class _MockReactionUseCase extends Mock implements ReactionUseCase {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockThemeUseCase extends Mock implements ThemeUseCase {}

const _me = AppUser(id: 'me', email: 'me@example.test', nickname: '카르마');

void main() {
  late _MockFeedUseCase feedUseCase;
  late _MockProfileUseCase profileUseCase;
  late _MockAuthBloc authBloc;
  late ThemeCubit themeCubit;

  setUp(() {
    feedUseCase = _MockFeedUseCase();
    profileUseCase = _MockProfileUseCase();
    authBloc = _MockAuthBloc();

    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(_me),
    );
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));
    when(() => profileUseCase.getMyProfile()).thenAnswer(
      (_) async => Ok(
        Profile(
          id: 'me',
          nickname: '카르마',
          createdAt: DateTime.utc(2026, 8, 24),
          updatedAt: DateTime.utc(2026, 8, 24),
        ),
      ),
    );

    getIt
      ..registerFactory<FeedCubit>(
        () => FeedCubit(feedUseCase, _MockReactionUseCase()),
      )
      ..registerFactory<PostCubit>(() => PostCubit(_MockPostUseCase()))
      ..registerFactory<ProfileCubit>(() => ProfileCubit(profileUseCase));

    final themeUseCase = _MockThemeUseCase();
    when(themeUseCase.loadThemeMode).thenReturn(AppThemeMode.system);
    themeCubit = ThemeCubit(themeUseCase);
    addTearDown(themeCubit.close);
  });

  tearDown(getIt.reset);

  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            // 실제 앱에서는 앱 루트가 제공한다. 설정 탭이 이걸 읽는다.
            BlocProvider<ThemeCubit>.value(value: themeCubit),
          ],
          child: const HomeShellPage(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('하단 내비게이션은 홈 · 프로필 · 설정 세 곳을 보여준다', (tester) async {
    await pumpShell(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(3));
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('프로필'), findsOneWidget);
    // 탭 라벨과 설정 화면의 제목이 같아서 처음에는 라벨 하나만 있다.
    expect(find.text('설정'), findsOneWidget);
  });

  testWidgets('탭을 옮기면 그 화면이 앞으로 나온다', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();

    // AppBar 제목과 탭 라벨 둘이 된다.
    expect(find.text('설정'), findsNWidgets(2));
    expect(find.text('로그아웃'), findsOneWidget);
  });

  testWidgets('탭을 오가도 목록을 다시 읽지 않는다', (tester) async {
    // IndexedStack 이 탭 본문을 살려 두므로 스크롤 위치와 읽어둔 페이지가 남는다.
    // 셸이 세 탭을 한 번에 만들기 때문에 첫 조회는 피드 탭과 프로필 탭에서
    // 각각 한 번씩 일어난다. 여기서 확인하려는 것은 **그다음**이다.
    await pumpShell(tester);
    await tester.pumpAndSettle();
    verify(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
      ),
    ).called(greaterThan(0));

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();

    // 탭을 오간 것만으로는 조회가 한 번도 더 일어나지 않는다.
    verifyNever(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
      ),
    );
  });
}
