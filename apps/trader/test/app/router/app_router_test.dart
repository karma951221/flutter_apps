import 'package:daylog/app/router/app_router.dart';
import 'package:core/core.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_chat/feature_chat.dart';
import 'package:daylog/features/post/domain/entity/post.dart';
import 'package:daylog/features/post/domain/entity/post_image.dart';
import 'package:daylog/features/post/presentation/cubit/post_cubit.dart';
import 'package:daylog/features/post/presentation/page/post_editor_page.dart';
import 'package:feature_trade/feature_trade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends Mock implements AuthBloc {}

/// 화면을 짓지 않고 라우트 표만 본다.
///
/// `/trade/:sessionId` 와 `/trade/:sessionId/result` 는 앞 두 세그먼트가 같다.
/// 등록 순서나 패턴을 잘못 두면 `result` 가 sessionId 로 잡혀 결과 링크가
/// 진행 화면으로 열린다 — 공유 링크가 통째로 망가지는 종류의 실수라서,
/// 화면이 아니라 매칭 자체를 검사한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GoRouter buildRouter() {
    final authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenReturn(
      const AuthState.authenticated(
        AppUser(id: 'u1', email: 'me@example.com', nickname: '나'),
      ),
    );
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    final router = createRouter(authBloc);
    addTearDown(router.dispose);
    return router;
  }

  String matchedPath(GoRouter router, String location) {
    final matches = router.configuration.findMatch(Uri.parse(location));
    expect(matches.isError, isFalse, reason: '$location 에 맞는 라우트가 없다');
    return (matches.matches.last as RouteMatch).route.path;
  }

  Future<Widget> buildMatchedRoute(
    WidgetTester tester,
    GoRouter router,
    String location,
    Object? extra,
  ) async {
    late Widget built;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final matches = router.configuration.findMatch(
              Uri.parse(location),
              extra: extra,
            );
            final match = matches.matches.last;
            final state = match.buildState(
              router.configuration,
              matches,
              metadata: const {},
            );
            built = (match.route as GoRoute).builder!(context, state);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return built;
  }

  test('/trade/:sessionId 는 판 진행 화면 라우트로 간다', () {
    final router = buildRouter();

    expect(matchedPath(router, '/trade/abc'), Routes.tradeSession);
    expect(
      router.configuration
          .findMatch(Uri.parse('/trade/abc'))
          .pathParameters['sessionId'],
      'abc',
    );
  });

  test('/trade/:sessionId/result 는 여전히 결과 화면 라우트로 간다', () {
    final router = buildRouter();

    expect(matchedPath(router, '/trade/abc/result'), Routes.tradeResult);
    // 'result' 가 sessionId 로 잡히지 않는다.
    expect(
      router.configuration
          .findMatch(Uri.parse('/trade/abc/result'))
          .pathParameters['sessionId'],
      'abc',
    );
  });

  testWidgets('게시물 수정 라우터가 중첩 Map을 PostEditorPage로 복원한다', (tester) async {
    final router = buildRouter();
    final post = Post(
      id: 'post-1',
      authorId: 'u1',
      content: '기록',
      createdAt: DateTime.utc(2026, 9, 9),
      updatedAt: DateTime.utc(2026, 9, 9, 1),
      images: const [
        PostImage(
          id: 'image-1',
          url: 'https://example.test/1.jpg',
          width: 10,
          height: 20,
          sortOrder: 0,
        ),
      ],
      tradeResult: TradeResultSummary(
        sessionId: 'session-1',
        symbol: 'BTCUSDT',
        startDay: DateTime(2026, 1, 1),
        endDay: DateTime(2026, 3, 1),
        returnPct: 1,
        buyHoldReturnPct: 2,
        maxDrawdownPct: 3,
        tradeCount: 4,
      ),
    );

    final built = await buildMatchedRoute(
      tester,
      router,
      Routes.postEditPath(post.id),
      post.toMap(),
    );
    final page = (built as BlocProvider<PostCubit>).child as PostEditorPage;

    expect(page.post, post);
  });

  testWidgets('게시물 수정 라우터는 어긋난 Map을 null로 떨어뜨린다', (tester) async {
    final router = buildRouter();

    final built = await buildMatchedRoute(
      tester,
      router,
      Routes.postEditPath('post-1'),
      {'id': 'post-1'},
    );
    final page = (built as BlocProvider<PostCubit>).child as PostEditorPage;

    expect(page.post, isNull);
  });

  testWidgets('채팅방 라우터가 Map을 ChatRoomPageArgs로 복원한다', (tester) async {
    final router = buildRouter();
    const args = ChatRoomPageArgs(title: '지우', isDirect: true);

    final built = await buildMatchedRoute(
      tester,
      router,
      Routes.chatRoomPath('room-1'),
      args.toMap(),
    );
    final page = built as ChatRoomPage;

    expect(page.roomId, 'room-1');
    expect(page.args?.title, '지우');
    expect(page.args?.isDirect, isTrue);
  });

  testWidgets('채팅방 라우터는 어긋난 Map을 null로 떨어뜨린다', (tester) async {
    final router = buildRouter();

    final built = await buildMatchedRoute(
      tester,
      router,
      Routes.chatRoomPath('room-1'),
      {'title': '지우'},
    );

    expect((built as ChatRoomPage).args, isNull);
  });
}
