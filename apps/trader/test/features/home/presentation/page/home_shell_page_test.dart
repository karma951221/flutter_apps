import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
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
import 'package:daylog/features/post/domain/entity/post.dart';
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
import 'package:daylog/features/trade/domain/entity/trade_session.dart';
import 'package:daylog/features/trade/domain/entity/trade_session_summary.dart';
import 'package:daylog/features/trade/domain/usecase/trade_use_case.dart';
import 'package:daylog/features/trade/presentation/cubit/trade_home_cubit.dart';
import 'package:l10n/l10n.dart';
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

class _MockTradeUseCase extends Mock implements TradeUseCase {}

const _me = AppUser(id: 'me', email: 'me@example.test', nickname: '카르마');

void main() {
  setUpAll(() => registerFallbackValue(FeedSource.all));

  late _MockFeedUseCase feedUseCase;
  late _MockProfileUseCase profileUseCase;
  late _MockAuthBloc authBloc;
  late _MockChatUseCase chatUseCase;
  late _MockTradeUseCase tradeUseCase;
  late ThemeCubit themeCubit;
  late LanguageCubit languageCubit;

  setUp(() {
    feedUseCase = _MockFeedUseCase();
    when(
      () => feedUseCase.createdPosts,
    ).thenAnswer((_) => const Stream<Post>.empty());
    profileUseCase = _MockProfileUseCase();
    authBloc = _MockAuthBloc();
    chatUseCase = _MockChatUseCase();
    when(
      chatUseCase.getMyRooms,
    ).thenAnswer((_) async => const Ok(<ChatRoomSummary>[]));
    tradeUseCase = _MockTradeUseCase();
    when(
      tradeUseCase.getActiveSession,
    ).thenAnswer((_) async => const Ok<TradeSession?>(null));
    when(
      () => tradeUseCase.getPastSessions(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async => const Ok(CursorPage<TradeSessionSummary>(items: [])),
    );

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
      )
      ..registerFactory<TradeHomeCubit>(() => TradeHomeCubit(tradeUseCase));

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

  testWidgets('하단 내비게이션은 투자 · 홈 · 채팅 · 프로필 · 설정 다섯 곳을 순서대로 보여준다', (
    tester,
  ) async {
    await pumpShell(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(find.text('투자'), findsOneWidget);
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('프로필'), findsOneWidget);
    // IndexedStack 이 고르지 않은 탭 본문을 offstage 로 두고 finder 는 그것을
    // 건너뛰므로, 지금 보이는 '채팅' 은 탭 라벨 하나뿐이다 ('설정' 과 같다).
    expect(find.text('채팅'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);

    final labels = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .map((destination) => destination.label)
        .toList();
    expect(labels, ['투자', '홈', '채팅', '프로필', '설정']);
  });

  testWidgets('처음 열면 투자 탭이 앞에 있다', (tester) async {
    await pumpShell(tester);
    await tester.pumpAndSettle();

    // 모의투자 홈의 AppBar 제목이다. 탭 라벨('투자')과 다른 문구라 이 화면이
    // 앞에 있다는 것만 가리킨다.
    expect(find.text('모의투자'), findsOneWidget);
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

    // 그리고 채팅 탭에만 붙는다. 탭 순서가 바뀌어도 옆 탭으로 옮겨가지 않는다.
    final chatTab = find.ancestor(
      of: find.text('채팅'),
      matching: find.byType(NavigationDestination),
    );
    expect(
      find.descendant(of: chatTab, matching: find.widgetWithText(Badge, '3')),
      findsWidgets,
    );
    final tradeTab = find.ancestor(
      of: find.text('투자'),
      matching: find.byType(NavigationDestination),
    );
    expect(
      find.descendant(of: tradeTab, matching: find.byType(Badge)),
      findsNothing,
    );
  });

  testWidgets('탭을 옮기면 그 화면이 앞으로 나온다', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();

    // AppBar 제목과 탭 라벨 둘이 된다.
    expect(find.text('설정'), findsNWidgets(2));
    expect(find.text('로그아웃'), findsOneWidget);
  });

  testWidgets('피드와 채팅 FAB 은 서로 다른 heroTag 를 쓴다', (tester) async {
    // IndexedStack 이 다섯 탭 본문을 모두 살려 두므로 화면에 보이지 않는
    // 탭의 FAB 도 트리에 있다. 기본 태그(둘 다 null)로 겹치면 라우트
    // 전환에서 "multiple heroes share the same tag" 단언이 난다.
    await pumpShell(tester);
    await tester.pumpAndSettle();

    // IndexedStack 이 감춘 탭은 Offstage 아래에 있다 — 기본 finder 는 그것을
    // 건너뛰므로 skipOffstage: false 로 살아 있는 FAB 을 모두 본다.
    final tags = tester
        .widgetList<FloatingActionButton>(
          find.byType(FloatingActionButton, skipOffstage: false),
        )
        .map((fab) => fab.heroTag)
        .toList();

    expect(tags, hasLength(2));
    expect(tags, everyElement(isNotNull));
    expect(tags.toSet(), hasLength(2));
  });

  testWidgets('탭을 오가도 목록을 다시 읽지 않는다', (tester) async {
    // IndexedStack 이 탭 본문을 살려 두므로 스크롤 위치와 읽어둔 페이지가 남는다.
    // 셸이 다섯 탭을 한 번에 만들기 때문에 첫 조회는 피드 탭과 프로필 탭에서
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
