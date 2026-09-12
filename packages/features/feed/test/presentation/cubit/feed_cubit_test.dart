import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:feature_feed/feature_feed.dart';
import 'package:feature_post/feature_post.dart';
import 'package:feature_reaction/feature_reaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFeedUseCase extends Mock implements FeedUseCase {}

class _MockReactionUseCase extends Mock implements ReactionUseCase {}

Post _post(String id, {String content = '', String authorId = 'author-id'}) =>
    Post(
      id: id,
      authorId: authorId,
      content: content.isEmpty ? '기록 $id' : content,
      createdAt: DateTime.utc(2026, 8, 22, 9),
      updatedAt: DateTime.utc(2026, 8, 22, 9),
    );

PostAuthor _author({String id = 'author-id', String nickname = '카르마'}) =>
    PostAuthor(id: id, nickname: nickname);

FeedPost _item(String id, {String nickname = '카르마'}) => FeedPost(
  post: _post(id),
  author: _author(nickname: nickname),
);

void main() {
  late _MockFeedUseCase useCase;
  late _MockReactionUseCase reactionUseCase;

  setUpAll(() {
    registerFallbackValue(FeedSource.all);
    registerFallbackValue(const ReactionTarget.post('_'));
    registerFallbackValue(ReactionType.like);
    registerFallbackValue(const ReactionSummary());
  });

  setUp(() {
    useCase = _MockFeedUseCase();
    reactionUseCase = _MockReactionUseCase();
  });

  blocTest<FeedCubit, FeedState>(
    '첫 조회 결과와 다음 커서를 상태에 담는다',
    setUp: () =>
        when(
          () => useCase.getFeedPosts(
            limit: any(named: 'limit'),
            cursor: any(named: 'cursor'),
            source: any(named: 'source'),
          ),
        ).thenAnswer(
          (_) async => Ok(
            CursorPage<FeedPost>(items: [_item('1')], nextCursor: 'cursor-1'),
          ),
        ),
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, FeedStatus.loaded);
      expect(cubit.state.items.single.id, '1');
      expect(cubit.state.items.single.author.nickname, '카르마');
      expect(cubit.state.nextCursor, 'cursor-1');
      expect(cubit.state.canLoadMore, isTrue);
    },
  );

  blocTest<FeedCubit, FeedState>(
    '조회 실패는 실패 상태로 남긴다',
    setUp: () => when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Err(Failure.network())),
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, FeedStatus.failure);
      expect(cubit.state.failure, isA<NetworkFailure>());
    },
  );

  blocTest<FeedCubit, FeedState>(
    '더 불러오면 직전 커서로 요청하고 결과를 이어 붙인다',
    setUp: () {
      when(
        () => useCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: null,
          source: any(named: 'source'),
        ),
      ).thenAnswer(
        (_) async => Ok(
          CursorPage<FeedPost>(items: [_item('1')], nextCursor: 'cursor-1'),
        ),
      );
      when(
        () => useCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: 'cursor-1',
          source: any(named: 'source'),
        ),
      ).thenAnswer(
        (_) async => Ok(
          CursorPage<FeedPost>(
            items: [_item('2', nickname: '이웃')],
            nextCursor: 'cursor-2',
          ),
        ),
      );
    },
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
    },
    verify: (cubit) {
      expect(cubit.state.items.map((item) => item.id), ['1', '2']);
      // 이어 붙인 페이지도 자기 작성자를 들고 온다.
      expect(cubit.state.items.map((item) => item.author.nickname), [
        '카르마',
        '이웃',
      ]);
      expect(cubit.state.nextCursor, 'cursor-2');
      expect(cubit.state.isLoadingMore, isFalse);
      verify(
        () => useCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: 'cursor-1',
          source: any(named: 'source'),
        ),
      ).called(1);
    },
  );

  blocTest<FeedCubit, FeedState>(
    '마지막 페이지에 닿으면 더 불러오지 않는다',
    setUp: () => when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => Ok(CursorPage<FeedPost>(items: [_item('1')]))),
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
    },
    verify: (cubit) {
      expect(cubit.state.canLoadMore, isFalse);
      // load 한 번뿐이어야 한다. loadMore 는 커서가 없으면 요청하지 않는다.
      verify(
        () => useCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
          source: any(named: 'source'),
        ),
      ).called(1);
    },
  );

  blocTest<FeedCubit, FeedState>(
    '작성·수정·삭제 결과를 재조회 없이 목록에 반영한다',
    setUp: () => when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => Ok(CursorPage<FeedPost>(items: [_item('1')]))),
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load();
      cubit.prependPost(_item('2', nickname: '이웃'));
      cubit.replacePost(_post('1', content: '고친 내용'));
      cubit.removePost('2');
    },
    verify: (cubit) {
      expect(cubit.state.items.single.id, '1');
      expect(cubit.state.items.single.post.content, '고친 내용');
      verify(
        () => useCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
          source: any(named: 'source'),
        ),
      ).called(1);
    },
  );

  blocTest<FeedCubit, FeedState>(
    '게시물을 수정해도 작성자는 그대로 둔다',
    // 수정 화면은 Post 만 돌려준다. 작성자를 거기서 다시 만들게 하면 그 화면이
    // 프로필까지 알아야 하고, 값이 비면 목록에서 이름이 사라진다.
    setUp: () =>
        when(
          () => useCase.getFeedPosts(
            limit: any(named: 'limit'),
            cursor: any(named: 'cursor'),
            source: any(named: 'source'),
          ),
        ).thenAnswer(
          (_) async =>
              Ok(CursorPage<FeedPost>(items: [_item('1', nickname: '카르마')])),
        ),
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load();
      cubit.replacePost(_post('1', content: '고친 내용'));
    },
    verify: (cubit) {
      expect(cubit.state.items.single.author.nickname, '카르마');
      expect(cubit.state.items.single.post.content, '고친 내용');
    },
  );

  blocTest<FeedCubit, FeedState>(
    '없는 게시물을 수정·삭제해도 목록은 그대로다',
    setUp: () => when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => Ok(CursorPage<FeedPost>(items: [_item('1')]))),
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load();
      cubit.replacePost(_post('없는-id', content: '무시된다'));
      cubit.removePost('없는-id');
    },
    verify: (cubit) {
      expect(cubit.state.items.single.id, '1');
      expect(cubit.state.items.single.post.content, '기록 1');
    },
  );

  blocTest<FeedCubit, FeedState>(
    '목록을 읽기 전에는 반영 요청을 무시한다',
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) => cubit.prependPost(_item('1')),
    expect: () => <FeedState>[],
  );

  blocTest<FeedCubit, FeedState>(
    '차단한 작성자의 게시물만 목록에서 걷어낸다',
    setUp: () =>
        when(
          () => useCase.getFeedPosts(
            limit: any(named: 'limit'),
            cursor: any(named: 'cursor'),
            source: any(named: 'source'),
          ),
        ).thenAnswer(
          (_) async => Ok(
            CursorPage<FeedPost>(
              items: [
                FeedPost(
                  post: _post('1', authorId: 'blocked-author'),
                  author: _author(id: 'blocked-author', nickname: '카르마'),
                ),
                FeedPost(
                  post: _post('2', authorId: 'other-author'),
                  author: _author(id: 'other-author', nickname: '이웃'),
                ),
                FeedPost(
                  post: _post('3', authorId: 'blocked-author'),
                  author: _author(id: 'blocked-author', nickname: '카르마'),
                ),
              ],
            ),
          ),
        ),
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load();
      cubit.removeAuthor('blocked-author');
    },
    verify: (cubit) {
      expect(cubit.state.items.map((item) => item.id), ['2']);
    },
  );

  blocTest<FeedCubit, FeedState>(
    '목록을 읽기 전의 차단 반영은 무시한다',
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) => cubit.removeAuthor('author-id'),
    expect: () => <FeedState>[],
  );

  test('더 불러오는 중에 차단하면 그 사이 응답이 와도 다시 나타나지 않는다 '
      '(stale snapshot 병합 버그)', () async {
    // loadMore 는 요청을 보내기 '전'의 state 를 캡처해 두었다가 응답이
    // 오면 그 캡처 위에 이어붙이는 방식이었다. removeAuthor 가 그 요청이
    // 떠 있는 동안 실행되면, 캡처된 스냅샷에는 아직 차단된 작성자의 글이
    // 남아 있어 응답을 이어붙일 때 되살아났다 — 이 테스트는 그 스냅샷이
    // 아니라 최신 state 위에 병합해야 통과한다.
    final loadMoreCompleter = Completer<Result<CursorPage<FeedPost>>>();

    when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: null,
        source: any(named: 'source'),
      ),
    ).thenAnswer(
      (_) async => Ok(
        CursorPage<FeedPost>(
          items: [
            FeedPost(
              post: _post('1', authorId: 'blocked-author'),
              author: _author(id: 'blocked-author', nickname: '카르마'),
            ),
            FeedPost(
              post: _post('2', authorId: 'other-author'),
              author: _author(id: 'other-author', nickname: '이웃'),
            ),
          ],
          nextCursor: 'cursor-1',
        ),
      ),
    );
    when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: 'cursor-1',
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) => loadMoreCompleter.future);

    final cubit = FeedCubit(useCase, reactionUseCase);
    await cubit.load();
    expect(cubit.state.items.map((item) => item.id), ['1', '2']);

    // loadMore 요청을 띄운 채로 둔다 — 아직 완료하지 않는다.
    final loadMoreFuture = cubit.loadMore();

    // 요청이 떠 있는 동안 차단이 들어온다. 이 mutator 는 지금의 state 에서
    // 곧바로 blocked-author 항목을 걷어낸다.
    cubit.removeAuthor('blocked-author');
    expect(cubit.state.items.map((item) => item.id), ['2']);

    // 이제 loadMore 응답이 도착한다. 이 응답 페이지 자체에는 차단된
    // 작성자가 없다 — 순수하게 stale snapshot 병합 문제만 검증한다.
    loadMoreCompleter.complete(
      Ok(
        CursorPage<FeedPost>(
          items: [
            FeedPost(
              post: _post('3', authorId: 'other-author'),
              author: _author(id: 'other-author', nickname: '이웃'),
            ),
          ],
        ),
      ),
    );
    await loadMoreFuture;

    expect(cubit.state.items.map((item) => item.id), ['2', '3']);
  });

  test('더 불러오는 중에 차단하면 응답 페이지에 실린 차단된 작성자의 글도 걸러낸다 '
      '(요청이 차단보다 먼저 나간 경우)', () async {
    // loadMore 의 요청은 차단이 걸리기 전에 이미 서버로 나갔을 수 있다 —
    // 그러면 서버가 아직 필터링하지 못한 그 작성자의 글이 응답 페이지 자체에
    // 그대로 담겨 온다. state 를 최신으로 병합하는 것만으로는 이 경우를
    // 막지 못한다 — 들어오는 페이지도 걷어낸 작성자 집합으로 걸러야 한다.
    final loadMoreCompleter = Completer<Result<CursorPage<FeedPost>>>();

    when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: null,
        source: any(named: 'source'),
      ),
    ).thenAnswer(
      (_) async => Ok(
        CursorPage<FeedPost>(
          items: [
            FeedPost(
              post: _post('1', authorId: 'blocked-author'),
              author: _author(id: 'blocked-author', nickname: '카르마'),
            ),
          ],
          nextCursor: 'cursor-1',
        ),
      ),
    );
    when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: 'cursor-1',
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) => loadMoreCompleter.future);

    final cubit = FeedCubit(useCase, reactionUseCase);
    await cubit.load();

    final loadMoreFuture = cubit.loadMore();
    cubit.removeAuthor('blocked-author');
    expect(cubit.state.items, isEmpty);

    // 응답 페이지 자체에 차단된 작성자의 글이 하나 더 실려 온다 — 요청이
    // 차단보다 먼저 나갔다는 뜻이다.
    loadMoreCompleter.complete(
      Ok(
        CursorPage<FeedPost>(
          items: [
            FeedPost(
              post: _post('2', authorId: 'blocked-author'),
              author: _author(id: 'blocked-author', nickname: '카르마'),
            ),
            FeedPost(
              post: _post('3', authorId: 'other-author'),
              author: _author(id: 'other-author', nickname: '이웃'),
            ),
          ],
        ),
      ),
    );
    await loadMoreFuture;

    expect(cubit.state.items.map((item) => item.id), ['3']);
  });

  blocTest<FeedCubit, FeedState>(
    '작성자 필터 조회는 첫 페이지도 다음 페이지도 그 작성자로 요청한다',
    setUp: () {
      when(
        () => useCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: null,
          authorId: 'author-id',
          source: any(named: 'source'),
        ),
      ).thenAnswer(
        (_) async => Ok(
          CursorPage<FeedPost>(items: [_item('1')], nextCursor: 'cursor-1'),
        ),
      );
      when(
        () => useCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: 'cursor-1',
          authorId: 'author-id',
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async => Ok(CursorPage<FeedPost>(items: [_item('2')])));
    },
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.loadForAuthor('author-id');
      await cubit.loadMore();
    },
    verify: (cubit) {
      expect(cubit.state.items.map((item) => item.id), ['1', '2']);
      // 다음 페이지에서 필터가 빠지면 남의 글이 프로필에 섞여 들어온다.
      verify(
        () => useCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: 'cursor-1',
          authorId: 'author-id',
          source: any(named: 'source'),
        ),
      ).called(1);
      verifyNever(
        () => useCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
          authorId: null,
          source: any(named: 'source'),
        ),
      );
    },
  );

  blocTest<FeedCubit, FeedState>(
    '새로고침해도 작성자 필터는 그대로 남는다',
    setUp: () => when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: 'author-id',
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => Ok(CursorPage<FeedPost>(items: [_item('1')]))),
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.loadForAuthor('author-id');
      await cubit.refresh();
    },
    verify: (cubit) {
      verify(
        () => useCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: null,
          authorId: 'author-id',
          source: any(named: 'source'),
        ),
      ).called(2);
    },
  );

  blocTest<FeedCubit, FeedState>(
    '전체 피드를 다시 읽으면 작성자 필터를 지운다',
    setUp: () => when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => Ok(CursorPage<FeedPost>(items: [_item('1')]))),
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.loadForAuthor('author-id');
      await cubit.load();
      await cubit.refresh();
    },
    verify: (cubit) {
      // load 이후의 새로고침까지 필터 없이 나가야 한 화면의 필터가 다른
      // 화면으로 새지 않는다.
      verify(
        () => useCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: null,
          authorId: null,
          source: any(named: 'source'),
        ),
      ).called(2);
    },
  );

  blocTest<FeedCubit, FeedState>(
    '반응 결과를 해당 항목에만 반영한다',
    setUp: () =>
        when(
          () => useCase.getFeedPosts(
            limit: any(named: 'limit'),
            cursor: any(named: 'cursor'),
            source: any(named: 'source'),
          ),
        ).thenAnswer(
          (_) async =>
              Ok(CursorPage<FeedPost>(items: [_item('1'), _item('2')])),
        ),
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load();
      cubit.applyReaction(
        '2',
        const ReactionSummary(
          counts: {ReactionType.like: 1},
          mine: ReactionType.like,
        ),
      );
    },
    verify: (cubit) {
      expect(cubit.state.items.first.reactions.mine, isNull);
      expect(cubit.state.items.last.reactions.mine, ReactionType.like);
      // 작성자는 반응으로 바뀌지 않는다.
      expect(cubit.state.items.last.author.nickname, '카르마');
    },
  );

  blocTest<FeedCubit, FeedState>(
    '댓글 수를 해당 항목에만 반영한다',
    setUp: () =>
        when(
          () => useCase.getFeedPosts(
            limit: any(named: 'limit'),
            cursor: any(named: 'cursor'),
            source: any(named: 'source'),
          ),
        ).thenAnswer(
          (_) async =>
              Ok(CursorPage<FeedPost>(items: [_item('1'), _item('2')])),
        ),
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load();
      cubit.applyCommentCount('1', 3);
    },
    verify: (cubit) {
      expect(cubit.state.items.first.commentCount, 3);
      expect(cubit.state.items.last.commentCount, 0);
    },
  );

  blocTest<FeedCubit, FeedState>(
    '목록을 읽기 전의 반응 반영은 무시한다',
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) => cubit.applyReaction('1', const ReactionSummary()),
    expect: () => <FeedState>[],
  );

  blocTest<FeedCubit, FeedState>(
    '감정은 눌린 즉시 반영되고 성공하면 서버가 준 값으로 남는다',
    setUp: () {
      when(
        () => useCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async => Ok(CursorPage<FeedPost>(items: [_item('1')])));
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
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load();
      await cubit.toggleReaction('1', ReactionType.like);
    },
    verify: (cubit) {
      expect(cubit.state.items.single.reactions.mine, ReactionType.like);
      verify(
        () => reactionUseCase.toggle(
          target: const ReactionTarget.post('1'),
          tapped: ReactionType.like,
          current: const ReactionSummary(),
        ),
      ).called(1);
    },
  );

  blocTest<FeedCubit, FeedState>(
    '감정 저장이 실패하면 이전 값으로 되돌린다',
    setUp: () {
      when(
        () => useCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async => Ok(CursorPage<FeedPost>(items: [_item('1')])));
      when(
        () => reactionUseCase.toggle(
          target: any(named: 'target'),
          tapped: any(named: 'tapped'),
          current: any(named: 'current'),
        ),
      ).thenAnswer((_) async => const Err(Failure.network()));
    },
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load();
      await cubit.toggleReaction('1', ReactionType.like);
    },
    verify: (cubit) {
      expect(cubit.state.items.single.reactions.mine, isNull);
      expect(cubit.state.items.single.reactions.counts, isEmpty);
    },
  );

  blocTest<FeedCubit, FeedState>(
    '없는 게시물의 감정은 저장을 시도하지 않는다',
    setUp: () => when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => Ok(CursorPage<FeedPost>(items: [_item('1')]))),
    build: () => FeedCubit(useCase, reactionUseCase),
    act: (cubit) async {
      await cubit.load();
      final result = await cubit.toggleReaction('9', ReactionType.like);
      expect(result, isA<Err<ReactionSummary>>());
    },
    verify: (_) => verifyNever(
      () => reactionUseCase.toggle(
        target: any(named: 'target'),
        tapped: any(named: 'tapped'),
        current: any(named: 'current'),
      ),
    ),
  );

  test('팔로잉 탭은 팔로잉 소스로 읽는다', () async {
    when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));
    final cubit = FeedCubit(useCase, reactionUseCase);
    addTearDown(cubit.close);

    await cubit.loadFollowing();

    verify(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: null,
        authorId: null,
        source: FeedSource.following,
      ),
    ).called(1);
  });

  test('탭을 옮기면 앞 소스의 늦은 첫 페이지 응답은 버린다', () async {
    // 전체 탭의 첫 조회가 떠 있는 동안 팔로잉 탭으로 옮기면, 팔로잉 응답이
    // 먼저 그려진 뒤에 전체 응답이 뒤늦게 도착한다. 소스는 요청을 보낼 때만
    // 읽히므로, 응답 시점에 세대를 보지 않으면 팔로잉 탭에 전체 피드가
    // 그대로 들어앉는다 (isClosed 는 cubit 이 살아 있으니 걸리지 않는다).
    final allCompleter = Completer<Result<CursorPage<FeedPost>>>();

    when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: null,
        authorId: null,
        source: FeedSource.all,
      ),
    ).thenAnswer((_) => allCompleter.future);
    when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: null,
        authorId: null,
        source: FeedSource.following,
      ),
    ).thenAnswer(
      (_) async =>
          Ok(CursorPage<FeedPost>(items: [_item('팔로잉-1', nickname: '이웃')])),
    );

    final cubit = FeedCubit(useCase, reactionUseCase);
    addTearDown(cubit.close);

    // 전체 탭의 조회를 띄운 채로 팔로잉 탭으로 옮긴다.
    final allFuture = cubit.load();
    await cubit.loadFollowing();
    expect(cubit.state.items.map((item) => item.id), ['팔로잉-1']);

    // 뒤늦게 전체 응답이 도착한다.
    allCompleter.complete(
      Ok(CursorPage<FeedPost>(items: [_item('전체-1')], nextCursor: 'all-1')),
    );
    await allFuture;

    expect(cubit.state.items.map((item) => item.id), ['팔로잉-1']);
    expect(cubit.state.nextCursor, isNull);
  });

  test('탭을 옮기면 앞 소스의 늦은 다음 페이지 응답도 버린다', () async {
    // 더 나쁜 쪽이다. loadMore 의 응답은 '최신 state 위에 병합'되므로, 탭을
    // 옮긴 뒤 도착하면 팔로잉 목록 뒤에 전체 피드가 이어 붙고 nextCursor 까지
    // 전체 피드의 것으로 덮인다 — 팔로잉 탭이 끝없는 전체 피드가 된다.
    // 게다가 _load 가 비운 걷어냄 목록 때문에 방금 차단한 작성자의 글도 그
    // 페이지를 타고 되살아난다.
    final loadMoreCompleter = Completer<Result<CursorPage<FeedPost>>>();

    when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: null,
        authorId: null,
        source: FeedSource.all,
      ),
    ).thenAnswer(
      (_) async =>
          Ok(CursorPage<FeedPost>(items: [_item('전체-1')], nextCursor: 'all-1')),
    );
    when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: 'all-1',
        authorId: null,
        source: FeedSource.all,
      ),
    ).thenAnswer((_) => loadMoreCompleter.future);
    when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: null,
        authorId: null,
        source: FeedSource.following,
      ),
    ).thenAnswer(
      (_) async => Ok(
        CursorPage<FeedPost>(
          items: [_item('팔로잉-1', nickname: '이웃')],
          nextCursor: 'following-1',
        ),
      ),
    );

    final cubit = FeedCubit(useCase, reactionUseCase);
    addTearDown(cubit.close);

    await cubit.load();
    final loadMoreFuture = cubit.loadMore();
    await cubit.loadFollowing();

    loadMoreCompleter.complete(
      Ok(CursorPage<FeedPost>(items: [_item('전체-2')], nextCursor: 'all-2')),
    );
    await loadMoreFuture;

    expect(cubit.state.items.map((item) => item.id), ['팔로잉-1']);
    expect(cubit.state.nextCursor, 'following-1');
    expect(cubit.state.isLoadingMore, isFalse);
  });

  test('팔로잉 탭에서 쓴 글은 목록에 넣지 않는다', () async {
    // following_posts_with_author 는 follows 를 조인하고 follows_not_self 가
    // 자기 팔로우를 막는다 — 내 글은 이 목록에 들어올 수 없다. 넣어 두면
    // 맨 위에 보였다가 새로고침 한 번에 사라져 글이 날아간 것처럼 보인다.
    when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer(
      (_) async =>
          Ok(CursorPage<FeedPost>(items: [_item('팔로잉-1', nickname: '이웃')])),
    );

    final cubit = FeedCubit(useCase, reactionUseCase);
    addTearDown(cubit.close);

    await cubit.loadFollowing();
    cubit.prependPost(_item('방금-쓴-글'));

    expect(cubit.state.items.map((item) => item.id), ['팔로잉-1']);

    // 전체 탭으로 돌아오면 다시 넣는다.
    await cubit.load();
    cubit.prependPost(_item('방금-쓴-글'));
    expect(cubit.state.items.map((item) => item.id), ['방금-쓴-글', '팔로잉-1']);
  });

  test('프로필 목록은 팔로잉 탭을 본 뒤에도 전체 소스로 읽는다', () async {
    when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));
    final cubit = FeedCubit(useCase, reactionUseCase);
    addTearDown(cubit.close);

    await cubit.loadFollowing();
    await cubit.loadForAuthor('author-1');

    verify(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: null,
        authorId: 'author-1',
        source: FeedSource.all,
      ),
    ).called(1);
  });

  group('watchCreatedPosts', () {
    late StreamController<Post> createdPosts;

    void stubPage(List<FeedPost> items) => when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => Ok(CursorPage<FeedPost>(items: items)));

    setUp(() {
      createdPosts = StreamController<Post>.broadcast();
      when(() => useCase.createdPosts).thenAnswer((_) => createdPosts.stream);
    });

    tearDown(() => createdPosts.close());

    /// 이벤트가 구독자에게 닿을 때까지 한 바퀴 돌린다.
    Future<void> emitCreated(Post post) async {
      createdPosts.add(post);
      await Future<void>.delayed(Duration.zero);
    }

    test('생성 이벤트로 온 게시물이 목록 맨 앞에 붙는다', () async {
      stubPage([_item('1')]);
      final cubit = FeedCubit(useCase, reactionUseCase);
      addTearDown(cubit.close);

      await cubit.load();
      cubit.watchCreatedPosts(_author(nickname: '카르마'));
      await emitCreated(_post('2', content: '새 글'));

      expect(cubit.state.items.map((item) => item.id), ['2', '1']);
      expect(cubit.state.items.first.author.nickname, '카르마');
    });

    test('같은 게시물이 반환값과 이벤트로 두 번 와도 한 번만 붙는다', () async {
      stubPage([_item('1')]);
      final cubit = FeedCubit(useCase, reactionUseCase);
      addTearDown(cubit.close);

      await cubit.load();
      cubit.watchCreatedPosts(_author());
      final created = _post('2', content: '새 글');
      // 작성 화면의 반환값으로 넣는 기존 경로.
      cubit.prependPost(FeedPost(post: created, author: _author()));
      await emitCreated(created);

      expect(cubit.state.items.map((item) => item.id), ['2', '1']);
    });

    test('팔로잉 목록에는 내 글을 넣지 않는다', () async {
      stubPage([_item('1')]);
      final cubit = FeedCubit(useCase, reactionUseCase);
      addTearDown(cubit.close);

      await cubit.loadFollowing();
      cubit.watchCreatedPosts(_author());
      await emitCreated(_post('2'));

      expect(cubit.state.items.map((item) => item.id), ['1']);
    });

    test('남의 프로필 목록을 보고 있으면 내 글을 넣지 않는다', () async {
      stubPage([_item('1')]);
      final cubit = FeedCubit(useCase, reactionUseCase);
      addTearDown(cubit.close);

      await cubit.loadForAuthor('other-author');
      cubit.watchCreatedPosts(_author(id: 'author-id'));
      await emitCreated(_post('2', authorId: 'author-id'));

      expect(cubit.state.items.map((item) => item.id), ['1']);
    });

    test('작성자가 아닌 글은 무시한다', () async {
      stubPage([_item('1')]);
      final cubit = FeedCubit(useCase, reactionUseCase);
      addTearDown(cubit.close);

      await cubit.load();
      cubit.watchCreatedPosts(_author(id: 'author-id'));
      await emitCreated(_post('2', authorId: 'other-author'));

      expect(cubit.state.items.map((item) => item.id), ['1']);
    });

    test('다시 부르면 앞선 구독은 걷힌다 — 한 이벤트가 두 번 붙지 않는다', () async {
      stubPage([_item('1')]);
      final cubit = FeedCubit(useCase, reactionUseCase);
      addTearDown(cubit.close);

      await cubit.load();
      cubit
        ..watchCreatedPosts(_author(nickname: '옛 이름'))
        ..watchCreatedPosts(_author(nickname: '새 이름'));
      await emitCreated(_post('2'));

      expect(cubit.state.items.map((item) => item.id), ['2', '1']);
      expect(cubit.state.items.first.author.nickname, '새 이름');
    });

    test('닫힌 뒤에 온 이벤트는 아무 일도 하지 않는다', () async {
      stubPage([_item('1')]);
      final cubit = FeedCubit(useCase, reactionUseCase);

      await cubit.load();
      cubit.watchCreatedPosts(_author());
      await cubit.close();

      await expectLater(emitCreated(_post('2')), completes);
      expect(cubit.state.items.map((item) => item.id), ['1']);
    });
  });
}
