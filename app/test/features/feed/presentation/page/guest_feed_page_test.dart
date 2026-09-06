import 'package:daylog/app/router/routes.dart';
import 'package:daylog/core/di/injection.dart';
import 'package:daylog/core/pagination/cursor_page.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/feed/domain/entity/feed_post.dart';
import 'package:daylog/features/feed/domain/entity/feed_source.dart';
import 'package:daylog/features/feed/domain/usecase/feed_use_case.dart';
import 'package:daylog/features/feed/presentation/cubit/feed_cubit.dart';
import 'package:daylog/features/feed/presentation/page/guest_feed_page.dart';
import 'package:daylog/features/post/domain/entity/post.dart';
import 'package:daylog/features/post/domain/entity/post_author.dart';
import 'package:daylog/features/reaction/domain/usecase/reaction_use_case.dart';
import 'package:daylog/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockFeedUseCase extends Mock implements FeedUseCase {}

class _MockReactionUseCase extends Mock implements ReactionUseCase {}

FeedPost _item(String id) => FeedPost(
  post: Post(
    id: id,
    authorId: 'other',
    content: '기록 $id',
    createdAt: DateTime.utc(2026, 9, 6, 9),
    updatedAt: DateTime.utc(2026, 9, 6, 9),
  ),
  author: const PostAuthor(id: 'other', nickname: '이웃'),
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
}
