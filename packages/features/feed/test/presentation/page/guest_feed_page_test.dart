import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_feed/feature_feed.dart';
import 'package:feature_post/feature_post.dart';
import 'package:feature_reaction/feature_reaction.dart';
import 'package:feature_trade/feature_trade.dart';
import 'package:l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockFeedUseCase extends Mock implements FeedUseCase {}

class _MockReactionUseCase extends Mock implements ReactionUseCase {}

FeedPost _item(
  String id, {
  List<PostImage> images = const [],
  TradeResultSummary? tradeResult,
}) => FeedPost(
  post: Post(
    id: id,
    authorId: 'other',
    content: '기록 $id',
    createdAt: DateTime.utc(2026, 9, 6, 9),
    updatedAt: DateTime.utc(2026, 9, 6, 9),
    images: images,
    tradeResult: tradeResult,
  ),
  author: const PostAuthor(id: 'other', nickname: '이웃'),
);

TradeResultSummary _summary() => TradeResultSummary(
  sessionId: 'session-1',
  symbol: 'BTCUSDT',
  startDay: DateTime.utc(2021, 11),
  endDay: DateTime.utc(2022, 1, 29),
  returnPct: 12.34,
  buyHoldReturnPct: 3,
  maxDrawdownPct: 8,
  tradeCount: 4,
);

PostImage _image(int order) => PostImage(
  id: 'image-$order',
  url: 'https://example.test/$order.jpg',
  width: 1080,
  height: 1080,
  sortOrder: order,
);

void main() {
  setUpAll(() => registerFallbackValue(FeedSource.all));

  late _MockFeedUseCase feedUseCase;

  setUp(() {
    feedUseCase = _MockFeedUseCase();
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer(
      (_) async => Ok(CursorPage<FeedPost>(items: [_item('1'), _item('2')])),
    );
    getIt.registerFactory<FeedCubit>(
      () => FeedCubit(feedUseCase, _MockReactionUseCase()),
    );
  });

  tearDown(getIt.reset);

  Future<GoRouter> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: Routes.explore,
      routes: [
        GoRoute(path: Routes.explore, builder: (_, _) => const GuestFeedPage()),
        GoRoute(
          path: Routes.signUp,
          builder: (_, _) => const Scaffold(body: Text('가입 화면')),
        ),
        GoRoute(
          path: Routes.signIn,
          builder: (_, _) => const Scaffold(body: Text('로그인 화면')),
        ),
        GoRoute(
          path: Routes.tradeResult,
          builder: (_, _) => const Scaffold(body: Text('판 결과 화면')),
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
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('전체 피드를 읽기 전용으로 보여준다', (tester) async {
    await pumpPage(tester);

    expect(find.text('둘러보기'), findsOneWidget);
    expect(find.text('기록 1'), findsOneWidget);
    expect(find.text('기록 2'), findsOneWidget);
    // 더보기(신고·차단·수정·삭제) 메뉴가 없다.
    expect(find.byIcon(Icons.more_vert), findsNothing);
    verify(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: FeedSource.all,
      ),
    ).called(1);
  });

  testWidgets('게시물을 누르면 가입 안내 시트가 뜨고 회원가입으로 간다', (tester) async {
    final router = await pumpPage(tester);

    await tester.tap(find.text('기록 1'));
    await tester.pumpAndSettle();

    expect(find.text('가입하면 반응과 댓글을 남길 수 있어요'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '회원가입'));
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, Routes.signUp);
  });

  testWidgets('안내 시트의 로그인은 로그인 화면으로 간다', (tester) async {
    final router = await pumpPage(tester);

    await tester.tap(find.text('기록 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '로그인'));
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, Routes.signIn);
  });

  // 사진 여러 장은 가로 목록으로 그려지고, 그 스크롤 알림이 세로 목록의
  // listener 까지 올라간다. 사진을 옆으로 넘긴 것만으로 다음 페이지를 읽던
  // 회귀(P2-2)를 막는다.
  testWidgets('사진을 옆으로 끝까지 넘겨도 다음 페이지를 읽지 않는다', (tester) async {
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
          items: [
            // 첫 항목의 사진 줄은 화면보다 넓어 실제로 옆으로 스크롤된다.
            _item('1', images: [for (var i = 0; i < 8; i++) _image(i)]),
            // 세로 목록도 화면보다 충분히 길게 둔다 — 짧으면 세로 쪽이
            // 이미 끝이라 무엇을 하든 다음 페이지를 읽는다.
            for (var i = 2; i <= 10; i++) _item('$i'),
          ],
          // 다음 커서가 있어야 더 읽을 수 있는 상태가 된다 — 없으면 이
          // 테스트는 고장 난 코드에서도 통과한다.
          nextCursor: 'next',
        ),
      ),
    );

    await pumpPage(tester);

    final strip = find
        .byWidgetPredicate(
          (widget) =>
              widget is ListView && widget.scrollDirection == Axis.horizontal,
        )
        .first;
    expect(strip, findsOneWidget);

    await tester.drag(strip, const Offset(-2000, 0));
    await tester.pump();

    verify(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).called(1);
  });

  testWidgets('게시물이 없으면 빈 안내를 보여준다', (tester) async {
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));

    await pumpPage(tester);

    expect(find.text('아직 게시물이 없습니다'), findsOneWidget);
    expect(find.text('첫 게시물 쓰기'), findsNothing);

    // 빈 화면도 막다른 길이 아니다 — 가입 안내로 이어진다.
    await tester.tap(find.widgetWithText(OutlinedButton, '회원가입'));
    await tester.pumpAndSettle();

    expect(find.text('가입하면 반응과 댓글을 남길 수 있어요'), findsOneWidget);
  });

  // 끝난 판의 결과는 게스트도 볼 수 있는 열린 화면이라, 카드가 보이고
  // 눌러서 결과로 들어갈 수 있어야 한다 (가입 안내가 아니다).
  testWidgets('판 결과가 붙은 게시물은 카드를 보여주고 결과 화면으로 간다', (tester) async {
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer(
      (_) async => Ok(
        CursorPage<FeedPost>(items: [_item('1', tradeResult: _summary())]),
      ),
    );

    final router = await pumpPage(tester);

    expect(find.byType(TradeResultCard), findsOneWidget);
    expect(find.text('BTC · 2021-11-01 ~ 2022-01-29'), findsOneWidget);
    expect(find.text('+12.34%'), findsOneWidget);
    expect(find.text('보유만 했을 때 +3.00% · 최대낙폭 −8.00% · 매매 4회'), findsOneWidget);

    await tester.tap(find.byType(TradeResultCard));
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, Routes.tradeResultPath('session-1'));
    expect(find.text('판 결과 화면'), findsOneWidget);
  });
}
