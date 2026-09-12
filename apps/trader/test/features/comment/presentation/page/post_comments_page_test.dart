import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:daylog/features/comment/domain/entity/post_comment.dart';
import 'package:daylog/features/comment/domain/usecase/comment_use_case.dart';
import 'package:daylog/features/comment/presentation/cubit/comment_cubit.dart';
import 'package:daylog/features/comment/presentation/page/post_comments_page.dart';
import 'package:l10n/l10n.dart';
import 'package:daylog/features/post/domain/entity/post_author.dart';
import 'package:feature_reaction/feature_reaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCommentUseCase extends Mock implements CommentUseCase {}

class _MockReactionUseCase extends Mock implements ReactionUseCase {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

const _me = AppUser(id: 'me', email: 'me@example.test', nickname: '카르마');
const _other = PostAuthor(id: 'other', nickname: '이웃');

PostComment _comment(
  String id, {
  String? parentId,
  int replyCount = 0,
  PostAuthor author = _other,
  bool deleted = false,
}) => PostComment(
  id: id,
  postId: 'post-1',
  parentId: parentId,
  author: author,
  content: deleted ? null : '댓글 $id',
  createdAt: DateTime.utc(2026, 8, 23, 9),
  deletedAt: deleted ? DateTime.utc(2026, 8, 23, 10) : null,
  replyCount: replyCount,
);

void main() {
  late _MockCommentUseCase useCase;
  late _MockAuthBloc authBloc;

  setUpAll(() => registerFallbackValue(_other));

  setUp(() {
    useCase = _MockCommentUseCase();
    authBloc = _MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(_me),
    );

    getIt.registerFactory<CommentCubit>(
      () => CommentCubit(useCase, _MockReactionUseCase()),
    );
  });

  tearDown(getIt.reset);

  void stubComments(List<PostComment> items) {
    when(
      () => useCase.getComments(
        postId: any(named: 'postId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => Ok(CursorPage<PostComment>(items: items)));
  }

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
          child: const PostCommentsPage(postId: 'post-1'),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('댓글이 없으면 첫 댓글을 권한다', (tester) async {
    stubComments([]);

    await pumpPage(tester);

    expect(find.text('첫 댓글을 남겨보세요.'), findsOneWidget);
  });

  testWidgets('삭제된 부모 댓글은 본문 자리에 안내만 남는다', (tester) async {
    stubComments([_comment('1', deleted: true, replyCount: 1)]);

    await pumpPage(tester);

    expect(find.text('삭제된 댓글입니다'), findsOneWidget);
    // 삭제된 댓글에는 답글 버튼을 그리지 않는다. 최종 판정은 트리거지만
    // 누를 수 없는 버튼을 보여주지 않는 것이 화면의 몫이다.
    expect(find.widgetWithText(TextButton, '답글'), findsNothing);
  });

  testWidgets('남의 댓글 메뉴에는 신고가 있다', (tester) async {
    stubComments([_comment('1')]);

    await pumpPage(tester);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('신고'), findsOneWidget);
    expect(find.text('삭제'), findsNothing);
  });

  testWidgets('내 댓글 메뉴에는 삭제가 있고 신고가 없다', (tester) async {
    stubComments([
      _comment(
        '1',
        author: const PostAuthor(id: 'me', nickname: '카르마'),
      ),
    ]);

    await pumpPage(tester);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('삭제'), findsOneWidget);
    expect(find.text('신고'), findsNothing);
  });

  testWidgets('삭제된 댓글에는 메뉴가 없다', (tester) async {
    stubComments([_comment('1', deleted: true)]);

    await pumpPage(tester);

    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('답글이 있는 댓글은 펼치기 버튼을 보여주고 눌러야 읽는다', (tester) async {
    stubComments([_comment('1', replyCount: 2)]);
    when(
      () => useCase.getReplies(
        parentId: any(named: 'parentId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async =>
          Ok(CursorPage<PostComment>(items: [_comment('r1', parentId: '1')])),
    );

    await pumpPage(tester);
    expect(find.text('답글 2개 보기'), findsOneWidget);
    verifyNever(
      () => useCase.getReplies(
        parentId: any(named: 'parentId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    );

    await tester.tap(find.text('답글 2개 보기'));
    await tester.pump();

    expect(find.text('댓글 r1'), findsOneWidget);
    expect(find.text('답글 숨기기'), findsOneWidget);
  });

  testWidgets('답글 버튼을 누르면 입력줄이 대상을 표시한다', (tester) async {
    stubComments([_comment('1')]);

    await pumpPage(tester);
    await tester.tap(find.widgetWithText(TextButton, '답글'));
    await tester.pump();

    expect(find.text('${_other.nickname} 님에게 답글'), findsOneWidget);
  });

  testWidgets('입력한 댓글을 등록하면 목록 끝에 붙는다', (tester) async {
    stubComments([_comment('1')]);
    when(
      () => useCase.addComment(
        postId: any(named: 'postId'),
        parentId: any(named: 'parentId'),
        content: any(named: 'content'),
        author: any(named: 'author'),
      ),
    ).thenAnswer(
      (_) async => Ok(
        _comment(
          '2',
          author: const PostAuthor(id: 'me', nickname: '카르마'),
        ),
      ),
    );

    await pumpPage(tester);
    await tester.enterText(find.byType(TextField), '새 댓글');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(find.text('댓글 2'), findsOneWidget);
    verify(
      () => useCase.addComment(
        postId: 'post-1',
        parentId: null,
        content: '새 댓글',
        author: any(named: 'author'),
      ),
    ).called(1);
  });
}
