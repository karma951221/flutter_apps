import 'package:core/core.dart';
import 'package:daylog/features/comment/domain/entity/post_comment.dart';
import 'package:daylog/features/comment/domain/repository/comment_repository.dart';
import 'package:daylog/features/comment/domain/usecase/scenario/add_comment_scenario.dart';
import 'package:daylog/features/comment/domain/usecase/scenario/delete_comment_scenario.dart';
import 'package:daylog/features/comment/domain/usecase/scenario/get_comments_scenario.dart';
import 'package:daylog/features/comment/domain/usecase/scenario/get_replies_scenario.dart';
import 'package:daylog/features/post/domain/entity/post_author.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCommentRepository extends Mock implements CommentRepository {}

void main() {
  late _MockCommentRepository repository;

  const author = PostAuthor(id: 'author-1', nickname: '카르마');

  PostComment comment() => PostComment(
    id: 'comment-1',
    postId: 'post-1',
    author: author,
    content: '댓글',
    createdAt: DateTime.utc(2026, 8, 23, 9),
  );

  setUpAll(() => registerFallbackValue(author));

  setUp(() => repository = _MockCommentRepository());

  group('GetCommentsScenario', () {
    test('허용 범위를 넘는 limit 은 요청 자체를 막는다', () async {
      final result = await GetCommentsScenario(repository)(
        postId: 'post-1',
        limit: 51,
      );

      expect(result, isA<Err<CursorPage<PostComment>>>());
      verifyNever(
        () => repository.getComments(
          postId: any(named: 'postId'),
          limit: any(named: 'limit'),
        ),
      );
    });

    test('공백뿐인 커서도 요청 자체를 막는다', () async {
      final result = await GetCommentsScenario(repository)(
        postId: 'post-1',
        limit: 20,
        cursor: '   ',
      );

      expect(result, isA<Err<CursorPage<PostComment>>>());
      verifyNever(
        () => repository.getComments(
          postId: any(named: 'postId'),
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      );
    });

    test('정상 범위는 저장소로 넘긴다', () async {
      when(
        () => repository.getComments(
          postId: any(named: 'postId'),
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer(
        (_) async => Ok(CursorPage<PostComment>(items: [comment()])),
      );

      final result = await GetCommentsScenario(repository)(
        postId: 'post-1',
        limit: 20,
      );

      expect((result as Ok).value.items.single.id, 'comment-1');
    });
  });

  group('GetRepliesScenario', () {
    test('부모 id 로 답글을 읽는다', () async {
      when(
        () => repository.getReplies(
          parentId: any(named: 'parentId'),
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer(
        (_) async => Ok(CursorPage<PostComment>(items: [comment()])),
      );

      await GetRepliesScenario(repository)(parentId: 'comment-1', limit: 20);

      verify(
        () => repository.getReplies(
          parentId: 'comment-1',
          limit: 20,
          cursor: null,
        ),
      ).called(1);
    });

    test('허용 범위를 넘는 limit 은 요청 자체를 막는다', () async {
      final result = await GetRepliesScenario(repository)(
        parentId: 'comment-1',
        limit: 0,
      );

      expect(result, isA<Err<CursorPage<PostComment>>>());
      verifyNever(
        () => repository.getReplies(
          parentId: any(named: 'parentId'),
          limit: any(named: 'limit'),
        ),
      );
    });
  });

  group('AddCommentScenario', () {
    test('앞뒤 공백을 다듬어 저장한다', () async {
      when(
        () => repository.addComment(
          postId: any(named: 'postId'),
          parentId: any(named: 'parentId'),
          content: any(named: 'content'),
          author: any(named: 'author'),
        ),
      ).thenAnswer((_) async => Ok(comment()));

      await AddCommentScenario(repository)(
        postId: 'post-1',
        content: '  댓글  ',
        author: author,
      );

      verify(
        () => repository.addComment(
          postId: 'post-1',
          parentId: null,
          content: '댓글',
          author: author,
        ),
      ).called(1);
    });

    test('답글은 parentId 를 그대로 넘긴다', () async {
      when(
        () => repository.addComment(
          postId: any(named: 'postId'),
          parentId: any(named: 'parentId'),
          content: any(named: 'content'),
          author: any(named: 'author'),
        ),
      ).thenAnswer((_) async => Ok(comment()));

      await AddCommentScenario(repository)(
        postId: 'post-1',
        parentId: 'comment-1',
        content: '답글',
        author: author,
      );

      verify(
        () => repository.addComment(
          postId: 'post-1',
          parentId: 'comment-1',
          content: '답글',
          author: author,
        ),
      ).called(1);
    });

    test('공백뿐인 본문은 저장하지 않는다', () async {
      final result = await AddCommentScenario(repository)(
        postId: 'post-1',
        content: '   ',
        author: author,
      );

      expect(result, isA<Err<PostComment>>());
      verifyNever(
        () => repository.addComment(
          postId: any(named: 'postId'),
          content: any(named: 'content'),
          author: any(named: 'author'),
        ),
      );
    });

    test('300자를 넘으면 저장하지 않는다', () async {
      final result = await AddCommentScenario(repository)(
        postId: 'post-1',
        content: 'ㄱ' * 301,
        author: author,
      );

      expect(result, isA<Err<PostComment>>());
      verifyNever(
        () => repository.addComment(
          postId: any(named: 'postId'),
          content: any(named: 'content'),
          author: any(named: 'author'),
        ),
      );
    });

    test('300자 정확히는 저장한다', () async {
      when(
        () => repository.addComment(
          postId: any(named: 'postId'),
          parentId: any(named: 'parentId'),
          content: any(named: 'content'),
          author: any(named: 'author'),
        ),
      ).thenAnswer((_) async => Ok(comment()));

      final result = await AddCommentScenario(repository)(
        postId: 'post-1',
        content: 'ㄱ' * 300,
        author: author,
      );

      expect(result, isA<Ok<PostComment>>());
    });
  });

  group('DeleteCommentScenario', () {
    test('빈 id 는 요청 자체를 막는다', () async {
      final result = await DeleteCommentScenario(repository)('  ');

      expect(result, isA<Err<bool>>());
      verifyNever(() => repository.deleteComment(any()));
    });

    test('저장소 결과를 그대로 돌려준다', () async {
      when(
        () => repository.deleteComment(any()),
      ).thenAnswer((_) async => const Ok(false));

      final result = await DeleteCommentScenario(repository)('comment-1');

      expect((result as Ok).value, isFalse);
    });
  });
}
