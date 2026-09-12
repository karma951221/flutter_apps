import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:daylog/features/comment/domain/entity/post_comment.dart';
import 'package:daylog/features/comment/domain/usecase/comment_use_case.dart';
import 'package:daylog/features/comment/presentation/cubit/comment_cubit.dart';
import 'package:daylog/features/comment/presentation/cubit/comment_state.dart';
import 'package:daylog/features/post/domain/entity/post_author.dart';
import 'package:feature_reaction/feature_reaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCommentUseCase extends Mock implements CommentUseCase {}

class _MockReactionUseCase extends Mock implements ReactionUseCase {}

const _author = PostAuthor(id: 'author-1', nickname: '카르마');

PostComment _comment(
  String id, {
  String? parentId,
  int replyCount = 0,
  ReactionSummary reactions = const ReactionSummary(),
}) => PostComment(
  id: id,
  postId: 'post-1',
  parentId: parentId,
  author: _author,
  content: '댓글 $id',
  createdAt: DateTime.utc(2026, 8, 23, 9),
  replyCount: replyCount,
  reactions: reactions,
);

void main() {
  late _MockCommentUseCase useCase;
  late _MockReactionUseCase reactionUseCase;

  setUpAll(() {
    registerFallbackValue(const ReactionTarget.comment('_'));
    registerFallbackValue(ReactionType.like);
    registerFallbackValue(const ReactionSummary());
    registerFallbackValue(_author);
  });

  setUp(() {
    useCase = _MockCommentUseCase();
    reactionUseCase = _MockReactionUseCase();
  });

  void stubComments(List<PostComment> items, {String? nextCursor}) {
    when(
      () => useCase.getComments(
        postId: any(named: 'postId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async =>
          Ok(CursorPage<PostComment>(items: items, nextCursor: nextCursor)),
    );
  }

  void stubReplies(List<PostComment> items, {String? nextCursor}) {
    when(
      () => useCase.getReplies(
        parentId: any(named: 'parentId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async =>
          Ok(CursorPage<PostComment>(items: items, nextCursor: nextCursor)),
    );
  }

  blocTest<CommentCubit, CommentState>(
    '첫 조회 결과와 다음 커서를 상태에 담는다',
    setUp: () => stubComments([_comment('1')], nextCursor: 'cursor-1'),
    build: () => CommentCubit(useCase, reactionUseCase),
    act: (cubit) => cubit.load('post-1'),
    verify: (cubit) {
      expect(cubit.state.status, CommentStatus.loaded);
      expect(cubit.state.items.single.id, '1');
      expect(cubit.state.canLoadMore, isTrue);
    },
  );

  blocTest<CommentCubit, CommentState>(
    '조회 실패는 실패 상태로 남는다',
    setUp: () => when(
      () => useCase.getComments(
        postId: any(named: 'postId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => const Err(Failure.network())),
    build: () => CommentCubit(useCase, reactionUseCase),
    act: (cubit) => cubit.load('post-1'),
    verify: (cubit) => expect(cubit.state.status, CommentStatus.failure),
  );

  blocTest<CommentCubit, CommentState>(
    '답글은 부모를 펼칠 때 한 번만 읽는다',
    setUp: () {
      stubComments([_comment('1', replyCount: 1)]);
      stubReplies([_comment('r1', parentId: '1')]);
    },
    build: () => CommentCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load('post-1');
      await cubit.toggleReplies('1');
      await cubit.toggleReplies('1'); // 접기
      await cubit.toggleReplies('1'); // 다시 펼치기
    },
    verify: (cubit) {
      expect(cubit.state.repliesOf('1').single.id, 'r1');
      expect(cubit.state.isExpanded('1'), isTrue);
      verify(
        () => useCase.getReplies(
          parentId: '1',
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ).called(1);
    },
  );

  blocTest<CommentCubit, CommentState>(
    '새 댓글은 목록 끝에 붙고 개수가 하나 는다',
    setUp: () {
      stubComments([_comment('1')]);
      when(
        () => useCase.addComment(
          postId: any(named: 'postId'),
          parentId: any(named: 'parentId'),
          content: any(named: 'content'),
          author: any(named: 'author'),
        ),
      ).thenAnswer((_) async => Ok(_comment('2')));
    },
    build: () => CommentCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load('post-1');
      await cubit.add(content: '새 댓글', author: _author);
    },
    verify: (cubit) {
      // 오래된 순 정렬이므로 새 댓글의 자리는 끝이다.
      expect(cubit.state.items.last.id, '2');
      expect(cubit.state.countDelta, 1);
    },
  );

  blocTest<CommentCubit, CommentState>(
    '답글을 쓰면 부모의 답글 수가 오르고 목록이 펼쳐진다',
    setUp: () {
      stubComments([_comment('1')]);
      when(
        () => useCase.addComment(
          postId: any(named: 'postId'),
          parentId: any(named: 'parentId'),
          content: any(named: 'content'),
          author: any(named: 'author'),
        ),
      ).thenAnswer((_) async => Ok(_comment('r1', parentId: '1')));
    },
    build: () => CommentCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load('post-1');
      await cubit.add(content: '답글', author: _author, parentId: '1');
    },
    verify: (cubit) {
      expect(cubit.state.items.single.replyCount, 1);
      expect(cubit.state.repliesOf('1').single.id, 'r1');
      expect(cubit.state.isExpanded('1'), isTrue);
      expect(cubit.state.countDelta, 1);
    },
  );

  blocTest<CommentCubit, CommentState>(
    '답글 없는 댓글을 지우면 목록에서 빠진다',
    setUp: () {
      stubComments([_comment('1'), _comment('2')]);
      when(
        () => useCase.deleteComment(any()),
      ).thenAnswer((_) async => const Ok(true));
    },
    build: () => CommentCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load('post-1');
      await cubit.delete(cubit.state.items.first);
    },
    verify: (cubit) {
      expect(cubit.state.items.single.id, '2');
      expect(cubit.state.countDelta, -1);
    },
  );

  blocTest<CommentCubit, CommentState>(
    '답글이 남은 부모를 지우면 본문만 사라지고 자리는 남는다',
    setUp: () {
      stubComments([_comment('1', replyCount: 2)]);
      when(
        () => useCase.deleteComment(any()),
      ).thenAnswer((_) async => const Ok(true));
    },
    build: () => CommentCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load('post-1');
      await cubit.delete(cubit.state.items.first);
    },
    verify: (cubit) {
      final parent = cubit.state.items.single;
      expect(parent.isDeleted, isTrue);
      expect(parent.content, isNull);
      expect(parent.replyCount, 2);
    },
  );

  blocTest<CommentCubit, CommentState>(
    '답글을 지우면 부모의 답글 수가 하나 준다',
    setUp: () {
      stubComments([_comment('1', replyCount: 1)]);
      stubReplies([_comment('r1', parentId: '1')]);
      when(
        () => useCase.deleteComment(any()),
      ).thenAnswer((_) async => const Ok(true));
    },
    build: () => CommentCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load('post-1');
      await cubit.toggleReplies('1');
      await cubit.delete(cubit.state.repliesOf('1').single);
    },
    verify: (cubit) {
      expect(cubit.state.repliesOf('1'), isEmpty);
      expect(cubit.state.items.single.replyCount, 0);
      expect(cubit.state.countDelta, -1);
    },
  );

  blocTest<CommentCubit, CommentState>(
    '남의 댓글 삭제(false)는 목록을 건드리지 않는다',
    setUp: () {
      stubComments([_comment('1')]);
      when(
        () => useCase.deleteComment(any()),
      ).thenAnswer((_) async => const Ok(false));
    },
    build: () => CommentCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load('post-1');
      await cubit.delete(cubit.state.items.first);
    },
    verify: (cubit) {
      expect(cubit.state.items.single.isDeleted, isFalse);
      expect(cubit.state.countDelta, 0);
    },
  );

  blocTest<CommentCubit, CommentState>(
    '댓글 감정은 눌린 즉시 반영되고 성공하면 그대로 남는다',
    setUp: () {
      stubComments([_comment('1')]);
      when(
        () => reactionUseCase.toggle(
          target: any(named: 'target'),
          tapped: any(named: 'tapped'),
          current: any(named: 'current'),
        ),
      ).thenAnswer(
        (_) async => const Ok(
          ReactionSummary(
            counts: {ReactionType.like: 1},
            mine: ReactionType.like,
          ),
        ),
      );
    },
    build: () => CommentCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load('post-1');
      await cubit.toggleReaction(cubit.state.items.first, ReactionType.like);
    },
    verify: (cubit) {
      expect(cubit.state.items.single.reactions.mine, ReactionType.like);
      verify(
        () => reactionUseCase.toggle(
          target: const ReactionTarget.comment('1'),
          tapped: ReactionType.like,
          current: const ReactionSummary(),
        ),
      ).called(1);
    },
  );

  blocTest<CommentCubit, CommentState>(
    '감정 저장이 실패하면 이전 값으로 돌아간다',
    setUp: () {
      stubComments([
        _comment(
          '1',
          reactions: const ReactionSummary(counts: {ReactionType.like: 2}),
        ),
      ]);
      when(
        () => reactionUseCase.toggle(
          target: any(named: 'target'),
          tapped: any(named: 'tapped'),
          current: any(named: 'current'),
        ),
      ).thenAnswer((_) async => const Err(Failure.network()));
    },
    build: () => CommentCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load('post-1');
      await cubit.toggleReaction(cubit.state.items.first, ReactionType.like);
    },
    verify: (cubit) {
      final reactions = cubit.state.items.single.reactions;
      expect(reactions.mine, isNull);
      expect(reactions.countOf(ReactionType.like), 2);
    },
  );

  blocTest<CommentCubit, CommentState>(
    '답글의 감정은 답글 목록에만 반영된다',
    setUp: () {
      stubComments([_comment('1', replyCount: 1)]);
      stubReplies([_comment('r1', parentId: '1')]);
      when(
        () => reactionUseCase.toggle(
          target: any(named: 'target'),
          tapped: any(named: 'tapped'),
          current: any(named: 'current'),
        ),
      ).thenAnswer(
        (_) async => const Ok(
          ReactionSummary(
            counts: {ReactionType.dislike: 1},
            mine: ReactionType.dislike,
          ),
        ),
      );
    },
    build: () => CommentCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load('post-1');
      await cubit.toggleReplies('1');
      await cubit.toggleReaction(
        cubit.state.repliesOf('1').single,
        ReactionType.dislike,
      );
    },
    verify: (cubit) {
      expect(
        cubit.state.repliesOf('1').single.reactions.mine,
        ReactionType.dislike,
      );
      expect(cubit.state.items.single.reactions.mine, isNull);
    },
  );

  blocTest<CommentCubit, CommentState>(
    '더 불러오기는 직전 커서로 요청해 이어 붙인다',
    setUp: () {
      when(
        () => useCase.getComments(
          postId: any(named: 'postId'),
          limit: any(named: 'limit'),
          cursor: null,
        ),
      ).thenAnswer(
        (_) async => Ok(
          CursorPage<PostComment>(items: [_comment('1')], nextCursor: 'c1'),
        ),
      );
      when(
        () => useCase.getComments(
          postId: any(named: 'postId'),
          limit: any(named: 'limit'),
          cursor: 'c1',
        ),
      ).thenAnswer(
        (_) async => Ok(CursorPage<PostComment>(items: [_comment('2')])),
      );
    },
    build: () => CommentCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load('post-1');
      await cubit.loadMore();
    },
    verify: (cubit) {
      expect(cubit.state.items.map((item) => item.id), ['1', '2']);
      expect(cubit.state.canLoadMore, isFalse);
    },
  );
}
