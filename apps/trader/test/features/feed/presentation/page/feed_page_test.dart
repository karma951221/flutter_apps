import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:daylog/features/auth/domain/entity/app_user.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_event.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_state.dart';
import 'package:daylog/features/feed/domain/entity/feed_post.dart';
import 'package:daylog/features/feed/domain/usecase/feed_use_case.dart';
import 'package:daylog/features/feed/domain/entity/feed_source.dart';
import 'package:daylog/features/feed/presentation/cubit/feed_cubit.dart';
import 'package:daylog/features/feed/presentation/page/feed_page.dart';
import 'package:daylog/features/post/domain/entity/post.dart';
import 'package:daylog/features/post/domain/entity/post_author.dart';
import 'package:daylog/features/post/domain/usecase/post_use_case.dart';
import 'package:daylog/features/post/presentation/cubit/post_cubit.dart';
import 'package:daylog/features/reaction/domain/usecase/reaction_use_case.dart';
import 'package:daylog/features/safety/domain/usecase/safety_use_case.dart';
import 'package:daylog/features/safety/presentation/cubit/block_action_cubit.dart';
import 'package:l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFeedUseCase extends Mock implements FeedUseCase {}

class _MockReactionUseCase extends Mock implements ReactionUseCase {}

class _MockPostUseCase extends Mock implements PostUseCase {}

class _MockSafetyUseCase extends Mock implements SafetyUseCase {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

const _me = AppUser(id: 'me', email: 'me@example.test', nickname: '카르마');

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

  late _MockFeedUseCase feedUseCase;
  late StreamController<Post> createdPosts;
  late _MockSafetyUseCase safetyUseCase;
  late _MockAuthBloc authBloc;

  setUp(() {
    feedUseCase = _MockFeedUseCase();
    createdPosts = StreamController<Post>.broadcast();
    when(() => feedUseCase.createdPosts).thenAnswer((_) => createdPosts.stream);
    safetyUseCase = _MockSafetyUseCase();
    authBloc = _MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(_me),
    );

    getIt
      ..registerFactory<FeedCubit>(
        () => FeedCubit(feedUseCase, _MockReactionUseCase()),
      )
      ..registerFactory<PostCubit>(() => PostCubit(_MockPostUseCase()))
      ..registerFactory<BlockActionCubit>(
        () => BlockActionCubit(safetyUseCase),
      );
  });

  tearDown(() {
    createdPosts.close();
    return getIt.reset();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        // ko 가 ARB template 언어라 원문이 곧 기대값이다 (계획서).
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const FeedPage(),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> openBlockMenu(WidgetTester tester) async {
    // 목록의 첫 항목('other')이 남의 글이라 신고·차단 메뉴를 그린다. 다른
    // 항목('me')은 수정·삭제 메뉴라 같은 아이콘을 쓰므로 첫 번째만 연다.
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 사용자 차단'));
    await tester.pumpAndSettle();
  }

  testWidgets('차단 확인 → 차단 → 목록에서 제거 → 성공 스낵바까지 이어진다', (tester) async {
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer(
      (_) async => Ok(
        CursorPage<FeedPost>(
          items: [_item('1', 'other', '이웃'), _item('2', 'me', '카르마')],
        ),
      ),
    );
    when(
      () => safetyUseCase.blockUser('other'),
    ).thenAnswer((_) async => const Ok(null));

    await pumpPage(tester);
    expect(find.text('기록 1'), findsOneWidget);

    await openBlockMenu(tester);

    // 확인 다이얼로그가 뜨고, 아직 차단은 호출되지 않는다.
    expect(find.text('이 사용자를 차단할까요?'), findsOneWidget);
    verifyNever(() => safetyUseCase.blockUser(any()));

    await tester.tap(find.text('차단'));
    await tester.pumpAndSettle();

    verify(() => safetyUseCase.blockUser('other')).called(1);
    // 차단한 작성자의 글이 목록에서 사라진다.
    expect(find.text('기록 1'), findsNothing);
    expect(find.text('기록 2'), findsOneWidget);
    expect(find.text('차단했습니다.'), findsOneWidget);
  });

  testWidgets('다이얼로그를 취소하면 차단하지 않는다', (tester) async {
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

    await pumpPage(tester);
    await openBlockMenu(tester);

    expect(find.text('이 사용자를 차단할까요?'), findsOneWidget);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    verifyNever(() => safetyUseCase.blockUser(any()));
    // 다이얼로그가 닫히고 게시물은 그대로 남는다.
    expect(find.text('이 사용자를 차단할까요?'), findsNothing);
    expect(find.text('기록 1'), findsOneWidget);
  });

  testWidgets('차단이 실패하면 목록은 그대로 두고 오류 스낵바를 보여준다', (tester) async {
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
    when(() => safetyUseCase.blockUser('other')).thenAnswer(
      (_) async => const Err(Failure.network(message: '네트워크에 연결할 수 없습니다')),
    );

    await pumpPage(tester);
    await openBlockMenu(tester);
    await tester.tap(find.text('차단'));
    await tester.pumpAndSettle();

    expect(find.text('기록 1'), findsOneWidget);
    expect(find.text('네트워크에 연결할 수 없습니다'), findsOneWidget);
  });

  testWidgets('피드는 전체·팔로잉 두 탭을 보여준다', (tester) async {
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));

    await pumpPage(tester);

    expect(find.text('전체'), findsOneWidget);
    expect(find.text('팔로잉'), findsOneWidget);
    verify(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: null,
        authorId: null,
        source: FeedSource.all,
      ),
    ).called(1);
  });

  testWidgets('팔로잉 탭으로 옮기면 팔로잉 소스로 다시 읽는다', (tester) async {
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));

    await pumpPage(tester);
    await tester.tap(find.text('팔로잉'));
    await tester.pumpAndSettle();

    verify(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: null,
        authorId: null,
        source: FeedSource.following,
      ),
    ).called(1);
    expect(find.text('팔로우한 사람이 없습니다'), findsOneWidget);
  });

  testWidgets('팔로잉 탭에서 실패하면 다시 시도도 팔로잉을 읽는다', (tester) async {
    // load() 를 부르면 _source 가 전체로 되돌아가, 탭은 팔로잉인데 전체 피드가
    // 그려지고 이후 무한스크롤까지 전체 커서를 따라간다 (2026-08-30 리뷰).
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));

    await pumpPage(tester);

    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Err(Failure.network(message: '연결 실패')));
    await tester.tap(find.text('팔로잉'));
    await tester.pumpAndSettle();
    expect(find.text('다시 시도'), findsOneWidget);

    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));
    // 최초 진입의 전체 피드 조회까지 세지 않도록, 재시도 직전에 기록을 비운다.
    clearInteractions(feedUseCase);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    verify(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: null,
        authorId: null,
        source: FeedSource.following,
      ),
    ).called(1);
    verifyNever(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: FeedSource.all,
      ),
    );
  });

  testWidgets('팔로잉 탭이 비어 있으면 사람 둘러보기로 전체 탭에 보낸다', (tester) async {
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: FeedSource.all,
      ),
    ).thenAnswer(
      (_) async => Ok(CursorPage<FeedPost>(items: [_item('1', 'other', '이웃')])),
    );
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: FeedSource.following,
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));

    await pumpPage(tester);
    await tester.tap(find.text('팔로잉'));
    await tester.pumpAndSettle();

    expect(find.text('팔로우한 사람이 없습니다'), findsOneWidget);
    expect(find.text('사람 둘러보기'), findsOneWidget);

    await tester.tap(find.text('사람 둘러보기'));
    await tester.pumpAndSettle();

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.controller!.index, 0);
    expect(find.text('기록 1'), findsOneWidget);
  });

  testWidgets('다른 화면에서 쓴 글이 생성 이벤트로 목록 맨 위에 붙는다', (tester) async {
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
    expect(find.text('기록 1'), findsOneWidget);
    expect(find.text('기록 2'), findsNothing);

    // 매매 결과 화면에서 띄운 작성 화면이 만든 글 — 이 화면은 반환값을 받지
    // 못하고 생성 이벤트로만 안다.
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

    expect(find.text('기록 2'), findsOneWidget);
    final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data);
    expect(texts, containsAllInOrder(<String>['기록 2', '기록 1']));
    // 목록에 붙이려고 전체를 다시 읽지 않는다.
    verify(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).called(1);
  });
}
