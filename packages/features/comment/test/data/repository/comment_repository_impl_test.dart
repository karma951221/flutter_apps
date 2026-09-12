import 'package:core/core.dart';
import 'package:feature_comment/feature_comment.dart';
import 'package:feature_post/feature_post.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCommentDataSource extends Mock implements CommentDataSource {}

PostCommentDto _dto(int index) => PostCommentDto(
  id: 'comment-$index',
  postId: 'post-1',
  authorId: 'author-1',
  authorNickname: '카르마',
  content: '댓글 $index',
  createdAt: DateTime.utc(2026, 8, 23, 9).add(Duration(minutes: index)),
);

void main() {
  late _MockCommentDataSource dataSource;
  late CommentRepositoryImpl repository;

  const author = PostAuthor(id: 'author-1', nickname: '카르마');

  setUp(() {
    dataSource = _MockCommentDataSource();
    repository = CommentRepositoryImpl(dataSource);
  });

  test('다음 페이지 유무를 알려고 한 개를 더 요청한다', () async {
    when(
      () => dataSource.getComments(
        postId: any(named: 'postId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => []);

    await repository.getComments(postId: 'post-1', limit: 20);

    verify(
      () => dataSource.getComments(postId: 'post-1', limit: 21, cursor: null),
    ).called(1);
  });

  test('요청한 개수보다 많이 오면 잘라내고 다음 커서를 만든다', () async {
    when(
      () => dataSource.getComments(
        postId: any(named: 'postId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => [_dto(0), _dto(1), _dto(2)]);

    final page =
        ((await repository.getComments(postId: 'post-1', limit: 2)) as Ok)
            .value;

    expect(page.items.length, 2);
    expect(page.hasMore, isTrue);
    // 커서는 마지막으로 **돌려준** 항목 기준이어야 한다. 잘라낸 항목 기준이면
    // 다음 페이지에서 한 건이 건너뛰어진다.
    expect(CommentCursor.decode(page.nextCursor)!.id, 'comment-1');
  });

  test('받은 커서를 해석해 데이터 원천에 넘긴다', () async {
    when(
      () => dataSource.getComments(
        postId: any(named: 'postId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => []);

    final cursor = CommentCursor(
      createdAt: DateTime.utc(2026, 8, 23, 9, 30),
      id: 'comment-1',
    );

    await repository.getComments(
      postId: 'post-1',
      limit: 20,
      cursor: cursor.encode(),
    );

    verify(
      () => dataSource.getComments(postId: 'post-1', limit: 21, cursor: cursor),
    ).called(1);
  });

  test('깨진 커서는 Err 로 돌려준다', () async {
    final result = await repository.getComments(
      postId: 'post-1',
      limit: 20,
      cursor: 'not-a-cursor',
    );

    expect(result, isA<Err<dynamic>>());
  });

  test('답글도 같은 규칙으로 페이지를 나눈다', () async {
    when(
      () => dataSource.getReplies(
        parentId: any(named: 'parentId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => [_dto(0)]);

    final page =
        ((await repository.getReplies(parentId: 'comment-1', limit: 20)) as Ok)
            .value;

    expect(page.items.single.id, 'comment-0');
    expect(page.hasMore, isFalse);
  });

  test('작성은 서버가 준 id·시각에 화면이 아는 작성자를 붙여 돌려준다', () async {
    when(
      () => dataSource.addComment(
        postId: any(named: 'postId'),
        parentId: any(named: 'parentId'),
        content: any(named: 'content'),
      ),
    ).thenAnswer(
      (_) async => (id: 'comment-9', createdAt: DateTime.utc(2026, 8, 23, 10)),
    );

    final comment =
        ((await repository.addComment(
                  postId: 'post-1',
                  content: '새 댓글',
                  author: author,
                ))
                as Ok)
            .value;

    expect(comment.id, 'comment-9');
    expect(comment.content, '새 댓글');
    expect(comment.author, author);
    expect(comment.replyCount, 0);
    expect(comment.isDeleted, isFalse);
  });

  test('답글 작성은 parentId 를 그대로 들고 온다', () async {
    when(
      () => dataSource.addComment(
        postId: any(named: 'postId'),
        parentId: any(named: 'parentId'),
        content: any(named: 'content'),
      ),
    ).thenAnswer(
      (_) async => (id: 'reply-1', createdAt: DateTime.utc(2026, 8, 23, 10)),
    );

    final comment =
        ((await repository.addComment(
                  postId: 'post-1',
                  parentId: 'comment-1',
                  content: '답글',
                  author: author,
                ))
                as Ok)
            .value;

    expect(comment.parentId, 'comment-1');
    expect(comment.isReply, isTrue);
  });

  test('로그인하지 않은 상태의 작성은 인증 실패다', () async {
    when(
      () => dataSource.addComment(
        postId: any(named: 'postId'),
        parentId: any(named: 'parentId'),
        content: any(named: 'content'),
      ),
    ).thenAnswer((_) async => null);

    final result = await repository.addComment(
      postId: 'post-1',
      content: '새 댓글',
      author: author,
    );

    expect(result, isA<Err<dynamic>>());
  });

  test('남의 댓글 삭제는 false 로 온다', () async {
    when(() => dataSource.deleteComment(any())).thenAnswer((_) async => false);

    final result = await repository.deleteComment('comment-1');

    expect((result as Ok).value, isFalse);
  });

  test('로그인하지 않은 상태의 삭제는 인증 실패다', () async {
    when(() => dataSource.deleteComment(any())).thenAnswer((_) async => null);

    final result = await repository.deleteComment('comment-1');

    expect(result, isA<Err<bool>>());
  });
}
