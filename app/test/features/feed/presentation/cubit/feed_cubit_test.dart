import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/pagination/cursor_page.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/feed/domain/usecase/feed_use_case.dart';
import 'package:daylog/features/feed/presentation/cubit/feed_cubit.dart';
import 'package:daylog/features/feed/presentation/cubit/feed_state.dart';
import 'package:daylog/features/post/domain/entity/post.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFeedUseCase extends Mock implements FeedUseCase {}

Post _post(String id) => Post(
  id: id,
  authorId: 'author-id',
  content: '기록 $id',
  createdAt: DateTime.utc(2026, 8, 22, 9),
  updatedAt: DateTime.utc(2026, 8, 22, 9),
);

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
        CursorPage<Post>(items: [_post('1')], nextCursor: 'cursor-1'),
      ),
    ),
    build: () => FeedCubit(useCase),
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, FeedStatus.loaded);
      expect(cubit.state.posts.single.id, '1');
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
          CursorPage<Post>(items: [_post('1')], nextCursor: 'cursor-1'),
        ),
      );
      when(
        () => useCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: 'cursor-1',
        ),
      ).thenAnswer(
        (_) async => Ok(
          CursorPage<Post>(items: [_post('2')], nextCursor: 'cursor-2'),
        ),
      );
    },
    build: () => FeedCubit(useCase),
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
    },
    verify: (cubit) {
      expect(cubit.state.posts.map((post) => post.id), ['1', '2']);
      expect(cubit.state.nextCursor, 'cursor-2');
      expect(cubit.state.isLoadingMore, isFalse);
      verify(
        () => useCase.getFeedPosts(limit: any(named: 'limit'), cursor: 'cursor-1'),
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
    ).thenAnswer(
      (_) async => Ok(CursorPage<Post>(items: [_post('1')])),
    ),
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
    ).thenAnswer(
      (_) async => Ok(CursorPage<Post>(items: [_post('1')])),
    ),
    build: () => FeedCubit(useCase),
    act: (cubit) async {
      await cubit.load();
      cubit.prependPost(_post('2'));
      cubit.replacePost(
        Post(
          id: '1',
          authorId: 'author-id',
          content: '고친 내용',
          createdAt: DateTime.utc(2026, 8, 22, 9),
          updatedAt: DateTime.utc(2026, 8, 22, 11),
        ),
      );
      cubit.removePost('2');
    },
    verify: (cubit) {
      expect(cubit.state.posts.single.id, '1');
      expect(cubit.state.posts.single.content, '고친 내용');
      verify(
        () => useCase.getFeedPosts(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ).called(1);
    },
  );

  blocTest<FeedCubit, FeedState>(
    '목록을 읽기 전에는 반영 요청을 무시한다',
    build: () => FeedCubit(useCase),
    act: (cubit) => cubit.prependPost(_post('1')),
    expect: () => <FeedState>[],
  );
}
