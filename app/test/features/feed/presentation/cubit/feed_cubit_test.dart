import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/pagination/cursor_page.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/feed/domain/entity/feed_post.dart';
import 'package:daylog/features/feed/domain/usecase/feed_use_case.dart';
import 'package:daylog/features/feed/presentation/cubit/feed_cubit.dart';
import 'package:daylog/features/feed/presentation/cubit/feed_state.dart';
import 'package:daylog/features/post/domain/entity/post.dart';
import 'package:daylog/features/post/domain/entity/post_author.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFeedUseCase extends Mock implements FeedUseCase {}

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

FeedPost _item(String id, {String nickname = '카르마'}) =>
    FeedPost(post: _post(id), author: _author(nickname: nickname));

void main() {
  late _MockFeedUseCase useCase;

  setUp(() => useCase = _MockFeedUseCase());

  blocTest<FeedCubit, FeedState>(
    '첫 조회 결과와 다음 커서를 상태에 담는다',
    setUp: () => when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async => Ok(
        CursorPage<FeedPost>(items: [_item('1')], nextCursor: 'cursor-1'),
      ),
    ),
    build: () => FeedCubit(useCase),
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
      ),
    ).thenAnswer((_) async => const Err(Failure.network())),
    build: () => FeedCubit(useCase),
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
        () => useCase.getFeedPosts(limit: any(named: 'limit'), cursor: null),
      ).thenAnswer(
        (_) async => Ok(
          CursorPage<FeedPost>(items: [_item('1')], nextCursor: 'cursor-1'),
        ),
      );
      when(
        () => useCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: 'cursor-1',
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
    build: () => FeedCubit(useCase),
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
    },
    verify: (cubit) {
      expect(cubit.state.items.map((item) => item.id), ['1', '2']);
      // 이어 붙인 페이지도 자기 작성자를 들고 온다.
      expect(
        cubit.state.items.map((item) => item.author.nickname),
        ['카르마', '이웃'],
      );
      expect(cubit.state.nextCursor, 'cursor-2');
      expect(cubit.state.isLoadingMore, isFalse);
      verify(
        () =>
            useCase.getFeedPosts(limit: any(named: 'limit'), cursor: 'cursor-1'),
      ).called(1);
    },
  );

  blocTest<FeedCubit, FeedState>(
    '마지막 페이지에 닿으면 더 불러오지 않는다',
    setUp: () => when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => Ok(CursorPage<FeedPost>(items: [_item('1')]))),
    build: () => FeedCubit(useCase),
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
      ),
    ).thenAnswer((_) async => Ok(CursorPage<FeedPost>(items: [_item('1')]))),
    build: () => FeedCubit(useCase),
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
        ),
      ).called(1);
    },
  );

  blocTest<FeedCubit, FeedState>(
    '게시물을 수정해도 작성자는 그대로 둔다',
    // 수정 화면은 Post 만 돌려준다. 작성자를 거기서 다시 만들게 하면 그 화면이
    // 프로필까지 알아야 하고, 값이 비면 목록에서 이름이 사라진다.
    setUp: () => when(
      () => useCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async =>
          Ok(CursorPage<FeedPost>(items: [_item('1', nickname: '카르마')])),
    ),
    build: () => FeedCubit(useCase),
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
      ),
    ).thenAnswer((_) async => Ok(CursorPage<FeedPost>(items: [_item('1')]))),
    build: () => FeedCubit(useCase),
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
    build: () => FeedCubit(useCase),
    act: (cubit) => cubit.prependPost(_item('1')),
    expect: () => <FeedState>[],
  );

  blocTest<FeedCubit, FeedState>(
    '작성자 필터 조회는 첫 페이지도 다음 페이지도 그 작성자로 요청한다',
    setUp: () {
      when(
        () => useCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: null,
          authorId: 'author-id',
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
        ),
      ).thenAnswer((_) async => Ok(CursorPage<FeedPost>(items: [_item('2')])));
    },
    build: () => FeedCubit(useCase),
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
        ),
      ).called(1);
      verifyNever(
        () => useCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
          authorId: null,
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
      ),
    ).thenAnswer((_) async => Ok(CursorPage<FeedPost>(items: [_item('1')]))),
    build: () => FeedCubit(useCase),
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
      ),
    ).thenAnswer((_) async => Ok(CursorPage<FeedPost>(items: [_item('1')]))),
    build: () => FeedCubit(useCase),
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
        ),
      ).called(2);
    },
  );
}
