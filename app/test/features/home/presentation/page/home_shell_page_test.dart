import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/core/di/injection.dart';
import 'package:daylog/core/pagination/cursor_page.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/auth/domain/entity/app_user.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_event.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_state.dart';
import 'package:daylog/features/chat/domain/entity/chat_room_summary.dart';
import 'package:daylog/features/chat/domain/usecase/chat_use_case.dart';
import 'package:daylog/features/chat/presentation/cubit/chat_room_list_cubit.dart';
import 'package:daylog/features/feed/domain/entity/feed_post.dart';
import 'package:daylog/features/feed/domain/usecase/feed_use_case.dart';
import 'package:daylog/features/feed/domain/entity/feed_source.dart';
import 'package:daylog/features/follow/domain/usecase/follow_use_case.dart';
import 'package:daylog/features/follow/presentation/cubit/follow_action_cubit.dart';
import 'package:daylog/features/feed/presentation/cubit/feed_cubit.dart';
import 'package:daylog/features/home/presentation/page/home_shell_page.dart';
import 'package:daylog/features/post/domain/usecase/post_use_case.dart';
import 'package:daylog/features/post/presentation/cubit/post_cubit.dart';
import 'package:daylog/features/preferences/domain/entity/app_language.dart';
import 'package:daylog/features/preferences/domain/entity/app_theme_mode.dart';
import 'package:daylog/features/preferences/domain/usecase/preferences_use_case.dart';
import 'package:daylog/features/preferences/presentation/cubit/language_cubit.dart';
import 'package:daylog/features/preferences/presentation/cubit/theme_cubit.dart';
import 'package:daylog/features/profile/domain/entity/profile.dart';
import 'package:daylog/features/profile/domain/usecase/profile_use_case.dart';
import 'package:daylog/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:daylog/features/reaction/domain/usecase/reaction_use_case.dart';
import 'package:daylog/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFeedUseCase extends Mock implements FeedUseCase {}

class _MockFollowUseCase extends Mock implements FollowUseCase {}

class _MockPostUseCase extends Mock implements PostUseCase {}

class _MockProfileUseCase extends Mock implements ProfileUseCase {}

class _MockReactionUseCase extends Mock implements ReactionUseCase {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockPreferencesUseCase extends Mock implements PreferencesUseCase {}

class _MockChatUseCase extends Mock implements ChatUseCase {}

const _me = AppUser(id: 'me', email: 'me@example.test', nickname: '카르마');

void main() {
  setUpAll(() => registerFallbackValue(FeedSource.all));

  late _MockFeedUseCase feedUseCase;
  late _MockProfileUseCase profileUseCase;
  late _MockAuthBloc authBloc;
  late _MockChatUseCase chatUseCase;
  late ThemeCubit themeCubit;
  late LanguageCubit languageCubit;

  setUp(() {
    feedUseCase = _MockFeedUseCase();
    profileUseCase = _MockProfileUseCase();
    authBloc = _MockAuthBloc();
    chatUseCase = _MockChatUseCase();
    when(
      chatUseCase.getMyRooms,
    ).thenAnswer((_) async => const Ok(<ChatRoomSummary>[]));

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
        source: any(named: 'source'),
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
      ..registerFactory<ProfileCubit>(() => ProfileCubit(profileUseCase))
      ..registerFactory<ChatRoomListCubit>(() => ChatRoomListCubit(chatUseCase))
      ..registerFactory<FollowActionCubit>(
        () => FollowActionCubit(_MockFollowUseCase()),
      );

    final preferencesUseCase = _MockPreferencesUseCase();
    when(preferencesUseCase.loadThemeMode).thenReturn(AppThemeMode.system);
    when(preferencesUseCase.loadLanguage).thenReturn(AppLanguage.system);
    themeCubit = ThemeCubit(preferencesUseCase);
    addTearDown(themeCubit.close);
    languageCubit = LanguageCubit(preferencesUseCase);
    addTearDown(languageCubit.close);
  });

  tearDown(getIt.reset);

  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        // 한국어 단언을 유지하려면 하니스가 ko 로 고정돼야 한다 (계획서).
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            // 실제 앱에서는 앱 루트가 제공한다. 설정 탭이 이걸 읽는다.
            BlocProvider<ThemeCubit>.value(value: themeCubit),
            BlocProvider<LanguageCubit>.value(value: languageCubit),
          ],
          child: const HomeShellPage(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('하단 내비게이션은 홈 · 채팅 · 프로필 · 설정 네 곳을 보여준다', (tester) async {
    await pumpShell(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('프로필'), findsOneWidget);
    // IndexedStack 이 고르지 않은 탭 본문을 offstage 로 두고 finder 는 그것을
    // 건너뛰므로, 지금 보이는 '채팅' 은 탭 라벨 하나뿐이다 ('설정' 과 같다).
    expect(find.text('채팅'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
  });

  testWidgets('안읽음이 있으면 채팅 탭에 배지가 붙는다', (tester) async {
    when(chatUseCase.getMyRooms).thenAnswer(
      (_) async => Ok([
        ChatRoomSummary(
          id: 'r1',
          title: '방',
          myNickname: '나',
          lastReadAt: DateTime.utc(2026, 8, 28),
          unreadCount: 3,
        ),
      ]),
    );

    await pumpShell(tester);
    await tester.pumpAndSettle();

    // 배지는 셸이 그린다 — 채팅 탭이 화면에 없을 때도 숫자를 알아야 한다.
    expect(find.widgetWithText(Badge, '3'), findsWidgets);
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
    // 셸이 네 탭을 한 번에 만들기 때문에 첫 조회는 피드 탭과 프로필 탭에서
    // 각각 한 번씩 일어난다. 여기서 확인하려는 것은 **그다음**이다.
    await pumpShell(tester);
    await tester.pumpAndSettle();
    verify(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
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
        source: any(named: 'source'),
      ),
    );
  });
}
