import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:daylog/features/chat/domain/usecase/chat_use_case.dart';
import 'package:daylog/features/chat/presentation/page/chat_room_page.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:daylog/features/feed/domain/entity/feed_post.dart';
import 'package:daylog/features/feed/domain/usecase/feed_use_case.dart';
import 'package:daylog/features/feed/domain/entity/feed_source.dart';
import 'package:daylog/features/feed/presentation/cubit/feed_cubit.dart';
import 'package:daylog/features/follow/domain/entity/follow_relation.dart';
import 'package:daylog/features/follow/domain/usecase/follow_use_case.dart';
import 'package:daylog/features/follow/presentation/cubit/follow_action_cubit.dart';
import 'package:daylog/features/post/domain/entity/post.dart';
import 'package:daylog/features/post/domain/entity/post_author.dart';
import 'package:daylog/features/post/domain/usecase/post_use_case.dart';
import 'package:daylog/features/post/presentation/cubit/post_cubit.dart';
import 'package:daylog/features/reaction/domain/usecase/reaction_use_case.dart';
import 'package:daylog/features/profile/domain/entity/profile.dart';
import 'package:daylog/features/profile/domain/usecase/profile_use_case.dart';
import 'package:daylog/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:daylog/features/profile/presentation/page/profile_page.dart';
import 'package:l10n/l10n.dart';
import 'package:feature_safety/feature_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileUseCase extends Mock implements ProfileUseCase {}

class _MockFeedUseCase extends Mock implements FeedUseCase {}

class _MockReactionUseCase extends Mock implements ReactionUseCase {}

class _MockPostUseCase extends Mock implements PostUseCase {}

class _MockSafetyUseCase extends Mock implements SafetyUseCase {}

class _MockFollowUseCase extends Mock implements FollowUseCase {}

class _MockChatUseCase extends Mock implements ChatUseCase {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

const _me = AppUser(id: 'me', email: 'me@example.test', nickname: '카르마');

Profile _profile(
  String id,
  String nickname, {
  int followerCount = 0,
  int followingCount = 0,
  FollowRelation relation = const FollowRelation(),
}) => Profile(
  id: id,
  nickname: nickname,
  createdAt: DateTime.utc(2026, 8, 22, 9),
  updatedAt: DateTime.utc(2026, 8, 22, 9),
  followerCount: followerCount,
  followingCount: followingCount,
  relation: relation,
);

FeedPost _item(String id, String authorId, String nickname) => FeedPost(
  post: Post(
    id: id,
    authorId: authorId,
    content: '기록 $id',
    createdAt: DateTime.utc(2026, 8, 22, 9),
    updatedAt: DateTime.utc(2026, 8, 22, 9),
  ),
  author: PostAuthor(id: authorId, nickname: nickname),
);

void main() {
  setUpAll(() => registerFallbackValue(FeedSource.all));

  late _MockProfileUseCase profileUseCase;
  late _MockFeedUseCase feedUseCase;
  late StreamController<Post> createdPosts;
  late _MockSafetyUseCase safetyUseCase;
  late _MockFollowUseCase followUseCase;
  late _MockChatUseCase chatUseCase;
  late _MockAuthBloc authBloc;

  setUp(() {
    profileUseCase = _MockProfileUseCase();
    feedUseCase = _MockFeedUseCase();
    createdPosts = StreamController<Post>.broadcast();
    when(() => feedUseCase.createdPosts).thenAnswer((_) => createdPosts.stream);
    safetyUseCase = _MockSafetyUseCase();
    followUseCase = _MockFollowUseCase();
    chatUseCase = _MockChatUseCase();
    when(
      () => safetyUseCase.isBlockedByMe(any()),
    ).thenAnswer((_) async => const Ok(false));
    authBloc = _MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(_me),
    );

    getIt
      ..registerFactory<ProfileCubit>(() => ProfileCubit(profileUseCase))
      ..registerFactory<FeedCubit>(
        () => FeedCubit(feedUseCase, _MockReactionUseCase()),
      )
      ..registerFactory<PostCubit>(() => PostCubit(_MockPostUseCase()))
      ..registerFactory<BlockActionCubit>(() => BlockActionCubit(safetyUseCase))
      ..registerFactory<FollowActionCubit>(
        () => FollowActionCubit(followUseCase),
      )
      // 메시지 버튼이 누를 때 직접 꺼내 쓴다.
      ..registerSingleton<ChatUseCase>(chatUseCase);
  });

  tearDown(() {
    createdPosts.close();
    return getIt.reset();
  });

  Future<void> pumpPage(WidgetTester tester, {String? userId}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        // ko 가 ARB template 언어라 원문이 곧 기대값이다 (계획서).
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: ProfilePage(userId: userId),
        ),
      ),
    );
    // 프로필 조회 → 피드 조회 순으로 이어지므로 두 번 펌프한다.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('내 프로필은 편집 버튼을 보여주고 내 게시물만 읽는다', (tester) async {
    when(
      profileUseCase.getMyProfile,
    ).thenAnswer((_) async => Ok(_profile('me', '카르마')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer(
      (_) async => Ok(CursorPage<FeedPost>(items: [_item('1', 'me', '카르마')])),
    );

    await pumpPage(tester);

    expect(find.text('프로필'), findsOneWidget);
    expect(find.text('프로필 편집'), findsOneWidget);
    // 완성도 카드가 첫 화면을 채우므로 목록은 스크롤해야 보인다.
    await tester.scrollUntilVisible(find.text('기록 1'), 200);
    expect(find.text('기록 1'), findsOneWidget);
    verify(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: null,
        authorId: 'me',
        source: any(named: 'source'),
      ),
    ).called(1);
  });

  testWidgets('타인 프로필에는 편집 버튼이 없고 그 작성자의 게시물만 읽는다', (tester) async {
    when(
      () => profileUseCase.getProfile('other'),
    ).thenAnswer((_) async => Ok(_profile('other', '이웃')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer(
      (_) async => Ok(CursorPage<FeedPost>(items: [_item('2', 'other', '이웃')])),
    );

    await pumpPage(tester, userId: 'other');

    expect(find.text('사용자 프로필'), findsOneWidget);
    expect(find.text('프로필 편집'), findsNothing);
    expect(find.text('기록 2'), findsOneWidget);
    // 남의 프로필에서 내 프로필을 읽으면 화면 주인이 바뀐다.
    verifyNever(profileUseCase.getMyProfile);
    verify(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: null,
        authorId: 'other',
        source: any(named: 'source'),
      ),
    ).called(1);
  });

  testWidgets('타인 프로필 AppBar 에는 신고 메뉴가 있다', (tester) async {
    when(
      () => profileUseCase.getProfile('other'),
    ).thenAnswer((_) async => Ok(_profile('other', '이웃')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));
    when(
      () => safetyUseCase.isBlockedByMe('other'),
    ).thenAnswer((_) async => const Ok(false));

    await pumpPage(tester, userId: 'other');
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('신고'), findsOneWidget);
    expect(find.text('차단'), findsOneWidget);
    expect(find.text('차단 해제'), findsNothing);
  });

  testWidgets('이미 차단한 타인 프로필은 차단 해제만 보인다', (tester) async {
    when(
      () => profileUseCase.getProfile('other'),
    ).thenAnswer((_) async => Ok(_profile('other', '이웃')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));
    when(
      () => safetyUseCase.isBlockedByMe('other'),
    ).thenAnswer((_) async => const Ok(true));

    await pumpPage(tester, userId: 'other');
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('차단'), findsNothing);
    expect(find.text('차단 해제'), findsOneWidget);
  });

  testWidgets('차단 상태 조회에 실패하면 차단 메뉴를 숨긴다', (tester) async {
    when(
      () => profileUseCase.getProfile('other'),
    ).thenAnswer((_) async => Ok(_profile('other', '이웃')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));
    when(
      () => safetyUseCase.isBlockedByMe('other'),
    ).thenAnswer((_) async => const Err(Failure.network()));

    await pumpPage(tester, userId: 'other');
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('차단'), findsNothing);
    expect(find.text('차단 해제'), findsNothing);
    expect(find.text('신고'), findsOneWidget);
  });

  testWidgets('내 프로필 AppBar 에는 메뉴가 없다', (tester) async {
    when(
      profileUseCase.getMyProfile,
    ).thenAnswer((_) async => Ok(_profile('me', '카르마')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));

    await pumpPage(tester);

    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('차단은 확인 뒤 실행하고 프로필 게시물을 다시 읽는다', (tester) async {
    when(
      () => profileUseCase.getProfile('other'),
    ).thenAnswer((_) async => Ok(_profile('other', '이웃')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));
    when(
      () => safetyUseCase.isBlockedByMe('other'),
    ).thenAnswer((_) async => const Ok(false));
    when(
      () => safetyUseCase.blockUser('other'),
    ).thenAnswer((_) async => const Ok(null));

    await pumpPage(tester, userId: 'other');
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('차단'));
    await tester.pumpAndSettle();

    verifyNever(() => safetyUseCase.blockUser(any()));
    await tester.tap(find.text('차단'));
    await tester.pumpAndSettle();

    verify(() => safetyUseCase.blockUser('other')).called(1);
    verify(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: null,
        authorId: 'other',
        source: any(named: 'source'),
      ),
    ).called(2);
  });

  testWidgets('AppBar 에서 차단 확인 다이얼로그를 취소하면 차단하지 않는다', (tester) async {
    when(
      () => profileUseCase.getProfile('other'),
    ).thenAnswer((_) async => Ok(_profile('other', '이웃')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));
    when(
      () => safetyUseCase.isBlockedByMe('other'),
    ).thenAnswer((_) async => const Ok(false));

    await pumpPage(tester, userId: 'other');
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('차단'));
    await tester.pumpAndSettle();

    expect(find.text('이 사용자를 차단할까요?'), findsOneWidget);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    verifyNever(() => safetyUseCase.blockUser(any()));
    expect(find.text('이 사용자를 차단할까요?'), findsNothing);
  });

  testWidgets('AppBar 에서 차단에 성공하면 메뉴를 다시 열었을 때 차단 해제만 보인다', (tester) async {
    when(
      () => profileUseCase.getProfile('other'),
    ).thenAnswer((_) async => Ok(_profile('other', '이웃')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));
    when(
      () => safetyUseCase.isBlockedByMe('other'),
    ).thenAnswer((_) async => const Ok(false));
    when(
      () => safetyUseCase.blockUser('other'),
    ).thenAnswer((_) async => const Ok(null));

    await pumpPage(tester, userId: 'other');
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('차단'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('차단'));
    await tester.pumpAndSettle();

    // 메뉴를 다시 연다.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('차단'), findsNothing);
    expect(find.text('차단 해제'), findsOneWidget);
  });

  testWidgets('차단 해제 뒤 프로필 게시물을 다시 읽는다', (tester) async {
    when(
      () => profileUseCase.getProfile('other'),
    ).thenAnswer((_) async => Ok(_profile('other', '이웃')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));
    when(
      () => safetyUseCase.isBlockedByMe('other'),
    ).thenAnswer((_) async => const Ok(true));
    when(
      () => safetyUseCase.unblockUser('other'),
    ).thenAnswer((_) async => const Ok(null));

    await pumpPage(tester, userId: 'other');
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    // 해제는 확인 없이 바로 실행된다 — 한 번만 누른다.
    await tester.tap(find.text('차단 해제'));
    await tester.pumpAndSettle();

    verify(() => safetyUseCase.unblockUser('other')).called(1);
    verify(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: null,
        authorId: 'other',
        source: any(named: 'source'),
      ),
    ).called(2);
  });

  testWidgets('프로필 조회에 실패하면 다시 시도할 수 있다', (tester) async {
    when(
      profileUseCase.getMyProfile,
    ).thenAnswer((_) async => const Err(Failure.network()));

    await pumpPage(tester);

    expect(find.text('다시 시도'), findsOneWidget);
    // 프로필을 못 읽었으면 누구의 게시물인지도 모른다.
    verifyNever(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    );
  });

  testWidgets('설정에서 프로필을 고치면 프로필 탭이 다시 읽는다', (tester) async {
    // 하단 내비게이션 셸이 이 화면을 살려 두므로, 세션 스냅샷이 바뀌면 다시
    // 읽지 않는 한 옛 닉네임이 그대로 남는다.
    final authStates = StreamController<AuthState>.broadcast();
    addTearDown(authStates.close);
    whenListen(
      authBloc,
      authStates.stream,
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
    when(
      profileUseCase.getMyProfile,
    ).thenAnswer((_) async => Ok(_profile('me', '카르마')));

    await pumpPage(tester);
    verify(profileUseCase.getMyProfile).called(1);

    authStates.add(
      const AuthState.authenticated(
        AppUser(id: 'me', email: 'me@example.test', nickname: '바뀐이름'),
      ),
    );
    await tester.pump();
    await tester.pump();

    verify(profileUseCase.getMyProfile).called(1);
  });

  testWidgets('남의 프로필은 내 세션이 바뀌어도 다시 읽지 않는다', (tester) async {
    final authStates = StreamController<AuthState>.broadcast();
    addTearDown(authStates.close);
    whenListen(
      authBloc,
      authStates.stream,
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
    when(
      () => profileUseCase.getProfile(any()),
    ).thenAnswer((_) async => Ok(_profile('other', '이웃')));

    await pumpPage(tester, userId: 'other');
    clearInteractions(profileUseCase);

    authStates.add(
      const AuthState.authenticated(
        AppUser(id: 'me', email: 'me@example.test', nickname: '바뀐이름'),
      ),
    );
    await tester.pump();
    await tester.pump();

    verifyNever(profileUseCase.getMyProfile);
  });

  group('팔로우', () {
    Future<void> pumpOther(
      WidgetTester tester, {
      required Profile profile,
    }) async {
      when(
        () => feedUseCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
          authorId: any(named: 'authorId'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));
      when(
        () => profileUseCase.getProfile(any()),
      ).thenAnswer((_) async => Ok(profile));

      await pumpPage(tester, userId: profile.id);
    }

    testWidgets('남의 프로필은 팔로우 버튼과 수를 보여준다', (tester) async {
      await pumpOther(
        tester,
        profile: _profile('other', '이웃', followerCount: 3, followingCount: 5),
      );

      expect(find.text('팔로우'), findsOneWidget);
      expect(find.text('팔로워'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('이미 팔로우 중이면 라벨이 팔로잉이다', (tester) async {
      await pumpOther(
        tester,
        profile: _profile(
          'other',
          '이웃',
          relation: const FollowRelation(isFollowing: true),
        ),
      );

      expect(find.text('팔로잉'), findsNWidgets(2)); // 버튼과 수 라벨
      expect(find.text('팔로우'), findsNothing);
    });

    testWidgets('서로 팔로우 중이면 맞팔로우로 보인다', (tester) async {
      await pumpOther(
        tester,
        profile: _profile(
          'other',
          '이웃',
          relation: const FollowRelation(isFollowing: true, isFollowedBy: true),
        ),
      );

      expect(find.text('맞팔로우'), findsOneWidget);
    });

    testWidgets('팔로우를 누르면 수가 먼저 늘고 usecase 를 부른다', (tester) async {
      when(
        () => followUseCase.followUser('other'),
      ).thenAnswer((_) async => const Ok(null));
      await pumpOther(
        tester,
        profile: _profile('other', '이웃', followerCount: 3),
      );

      await tester.tap(find.text('팔로우'));
      await tester.pump();

      expect(find.text('4'), findsOneWidget);
      expect(find.text('팔로잉'), findsNWidgets(2));
      verify(() => followUseCase.followUser('other')).called(1);
    });

    testWidgets('실패하면 수를 되돌리고 오류를 알린다', (tester) async {
      when(() => followUseCase.followUser('other')).thenAnswer(
        (_) async => const Err(
          Failure.forbidden(
            message: '거부',
            failureCode: FailureCode.followBlocked,
          ),
        ),
      );
      await pumpOther(
        tester,
        profile: _profile('other', '이웃', followerCount: 3),
      );

      await tester.tap(find.text('팔로우'));
      await tester.pump();
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('지금은 팔로우할 수 없습니다'), findsOneWidget);
    });

    testWidgets('같은 프로필을 다시 읽으면 팔로워 수와 버튼이 갱신된다', (tester) async {
      // seed 가 id 변경에만 걸려 있어, 당겨서 새로고침으로 새 값을 받아도
      // 팔로잉 수만 갱신되고 팔로워 수·버튼은 옛 값에 멈춰 있었다. 그 상태로
      // 누르면 이미 있는 행을 다시 넣으려다 실패한다 (2026-08-30 리뷰).
      await pumpOther(
        tester,
        profile: _profile('other', '이웃', followerCount: 10),
      );
      expect(find.text('10'), findsOneWidget);
      expect(find.text('팔로우'), findsOneWidget);

      when(() => profileUseCase.getProfile(any())).thenAnswer(
        (_) async => Ok(
          _profile(
            'other',
            '이웃',
            followerCount: 11,
            relation: const FollowRelation(isFollowing: true),
          ),
        ),
      );
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('11'), findsOneWidget);
      expect(find.text('팔로잉'), findsNWidgets(2));
      expect(find.text('팔로우'), findsNothing);
    });
    testWidgets('내 프로필에는 팔로우 버튼이 없다', (tester) async {
      when(
        () => feedUseCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
          authorId: any(named: 'authorId'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));
      when(
        profileUseCase.getMyProfile,
      ).thenAnswer((_) async => Ok(_profile('me', '카르마', followerCount: 2)));

      await pumpPage(tester);

      expect(find.text('팔로우'), findsNothing);
      // 수는 내 프로필에서도 보인다.
      expect(find.text('팔로워'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('차단한 상대에게는 팔로우 버튼을 그리지 않는다', (tester) async {
      when(
        () => safetyUseCase.isBlockedByMe(any()),
      ).thenAnswer((_) async => const Ok(true));

      await pumpOther(tester, profile: _profile('other', '이웃'));

      expect(find.text('팔로우'), findsNothing);
    });
  });

  group('메시지', () {
    /// 버튼을 누르면 방으로 push 하므로 라우터가 필요하다. 방 화면이 실제로
    /// 받은 [ChatRoomPageArgs] 와 방 id 를 돌려준다.
    Future<({ChatRoomPageArgs? Function() args, String? Function() roomId})>
    pumpWithRouter(WidgetTester tester, {String userId = 'other'}) async {
      when(
        () => feedUseCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
          authorId: any(named: 'authorId'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));
      when(
        () => profileUseCase.getProfile(any()),
      ).thenAnswer((_) async => Ok(_profile('other', '이웃')));
      when(
        profileUseCase.getMyProfile,
      ).thenAnswer((_) async => Ok(_profile('me', '카르마')));

      ChatRoomPageArgs? args;
      String? roomId;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: Routes.home,
            builder: (_, _) => BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: ProfilePage(userId: userId == 'me' ? null : userId),
            ),
          ),
          GoRoute(
            path: Routes.chatRoom,
            builder: (_, state) {
              args = ChatRoomPageArgs.fromMap(state.extra);
              roomId = state.pathParameters['roomId'];
              return const Scaffold(body: Text('방 화면'));
            },
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
      await tester.pump();
      await tester.pump();

      return (args: () => args, roomId: () => roomId);
    }

    testWidgets('타인 프로필에는 팔로우 옆에 메시지 버튼이 있다', (tester) async {
      await pumpWithRouter(tester);

      expect(find.text('메시지'), findsOneWidget);
      expect(find.text('팔로우'), findsOneWidget);
    });

    testWidgets('내 프로필에는 메시지 버튼이 없다', (tester) async {
      await pumpWithRouter(tester, userId: 'me');

      expect(find.text('메시지'), findsNothing);
    });

    testWidgets('차단한 상대에게는 메시지 버튼을 그리지 않는다', (tester) async {
      // 대화 시작도 어차피 거부된다. 거부 문구로 관계를 설명하게 되면 차단
      // 사실이 새는 자리가 된다.
      when(
        () => safetyUseCase.isBlockedByMe(any()),
      ).thenAnswer((_) async => const Ok(true));

      await pumpWithRouter(tester);

      expect(find.text('메시지'), findsNothing);
    });

    testWidgets('메시지를 누르면 열린 방으로 상대 닉네임과 함께 들어간다', (tester) async {
      when(
        () => chatUseCase.openDirectRoom('other'),
      ).thenAnswer((_) async => const Ok('dm-1'));

      final captured = await pumpWithRouter(tester);
      await tester.tap(find.text('메시지'));
      await tester.pumpAndSettle();

      verify(() => chatUseCase.openDirectRoom('other')).called(1);
      expect(captured.roomId(), 'dm-1');
      expect(captured.args()?.title, '이웃');
      expect(captured.args()?.isDirect, isTrue);
      expect(find.text('방 화면'), findsOneWidget);
    });

    testWidgets('여는 동안 다시 눌러도 한 번만 요청한다', (tester) async {
      final completer = Completer<Result<String>>();
      when(
        () => chatUseCase.openDirectRoom('other'),
      ).thenAnswer((_) => completer.future);

      await pumpWithRouter(tester);
      await tester.tap(find.text('메시지'));
      await tester.pump();
      // 아직 응답 전이다 — 두 번째 탭은 버튼이 막는다.
      await tester.tap(find.text('메시지'));
      await tester.pump();

      verify(() => chatUseCase.openDirectRoom('other')).called(1);

      completer.complete(const Ok('dm-1'));
      await tester.pumpAndSettle();
    });

    testWidgets('시작할 수 없으면 지역화된 문구로 알리고 화면에 남는다', (tester) async {
      when(() => chatUseCase.openDirectRoom('other')).thenAnswer(
        (_) async => const Err(
          Failure.forbidden(
            message: '거부',
            failureCode: FailureCode.directChatNotAllowed,
          ),
        ),
      );

      final captured = await pumpWithRouter(tester);
      await tester.tap(find.text('메시지'));
      await tester.pumpAndSettle();

      expect(find.text('대화를 시작할 수 없습니다'), findsOneWidget);
      expect(captured.roomId(), isNull);
      // 실패해도 버튼은 다시 누를 수 있어야 한다.
      expect(
        tester
            .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '메시지'))
            .onPressed,
        isNotNull,
      );
    });
  });

  testWidgets('내 프로필은 완성도 카드를 20% 로 시작한다', (tester) async {
    when(
      profileUseCase.getMyProfile,
    ).thenAnswer((_) async => Ok(_profile('me', '카르마')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('프로필 완성 20%'), findsOneWidget);
  });

  testWidgets('내 게시물이 있으면 40% 로 오르고 첫 게시물 항목이 사라진다', (tester) async {
    when(
      profileUseCase.getMyProfile,
    ).thenAnswer((_) async => Ok(_profile('me', '카르마')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer(
      (_) async => Ok(CursorPage<FeedPost>(items: [_item('1', 'me', '카르마')])),
    );

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('프로필 완성 40%'), findsOneWidget);
    expect(find.text('첫 게시물 남기기'), findsNothing);
  });

  testWidgets('타인 프로필에는 완성도 카드가 없다', (tester) async {
    when(
      () => profileUseCase.getProfile('other'),
    ).thenAnswer((_) async => Ok(_profile('other', '이웃')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));

    await pumpPage(tester, userId: 'other');
    await tester.pumpAndSettle();

    expect(find.textContaining('프로필 완성'), findsNothing);
  });

  testWidgets('내 프로필은 다른 화면에서 쓴 글을 생성 이벤트로 받아 맨 위에 붙인다', (tester) async {
    when(
      profileUseCase.getMyProfile,
    ).thenAnswer((_) async => Ok(_profile('me', '카르마')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer(
      (_) async => Ok(CursorPage<FeedPost>(items: [_item('1', 'me', '카르마')])),
    );

    await pumpPage(tester);
    await tester.pumpAndSettle();
    expect(find.text('기록 2'), findsNothing);

    createdPosts.add(
      Post(
        id: '2',
        authorId: 'me',
        content: '기록 2',
        createdAt: DateTime.utc(2026, 9, 9, 9),
        updatedAt: DateTime.utc(2026, 9, 9, 9),
      ),
    );
    await tester.pumpAndSettle();

    // 완성도 카드 아래가 목록이라 새 글은 화면 밖에 그려진다.
    await tester.scrollUntilVisible(find.text('기록 2'), 200);
    expect(find.text('기록 2'), findsOneWidget);
    // 붙이려고 목록을 다시 읽지 않는다 — 프로필을 열 때 읽은 한 번뿐이다.
    verify(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).called(1);
  });

  testWidgets('타인 프로필은 내 글의 생성 이벤트를 듣지 않는다', (tester) async {
    when(
      () => profileUseCase.getProfile('other'),
    ).thenAnswer((_) async => Ok(_profile('other', '이웃')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer(
      (_) async => Ok(CursorPage<FeedPost>(items: [_item('1', 'other', '이웃')])),
    );

    await pumpPage(tester, userId: 'other');
    await tester.pumpAndSettle();

    createdPosts.add(
      Post(
        id: '2',
        authorId: 'me',
        content: '기록 2',
        createdAt: DateTime.utc(2026, 9, 9, 9),
        updatedAt: DateTime.utc(2026, 9, 9, 9),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('기록 2'), findsNothing);
    expect(find.text('기록 1'), findsOneWidget);
    verifyNever(() => feedUseCase.createdPosts);
  });
}
