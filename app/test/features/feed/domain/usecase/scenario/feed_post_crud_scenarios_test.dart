import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/feed/domain/entity/feed_post.dart';
import 'package:daylog/features/feed/domain/entity/feed_post_update.dart';
import 'package:daylog/features/feed/domain/repository/feed_repository.dart';
import 'package:daylog/features/feed/domain/usecase/scenario/delete_feed_post_scenario.dart';
import 'package:daylog/features/feed/domain/usecase/scenario/get_feed_post_scenario.dart';
import 'package:daylog/features/feed/domain/usecase/scenario/get_feed_posts_scenario.dart';
import 'package:daylog/features/feed/domain/usecase/scenario/update_feed_post_scenario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late _MockFeedRepository repository;

  setUpAll(() {
    registerFallbackValue(const FeedPostUpdate(content: 'fallback'));
  });

  setUp(() => repository = _MockFeedRepository());

  test('최신순 목록 조회를 저장소에 위임한다', () async {
    when(
      () => repository.getFeedPosts(limit: 20, offset: 0),
    ).thenAnswer((_) async => const Ok([]));

    final result = await GetFeedPostsScenario(repository)(limit: 20, offset: 0);

    expect(result, isA<Ok<List<FeedPost>>>());
    verify(() => repository.getFeedPosts(limit: 20, offset: 0)).called(1);
  });

  test('허용 범위를 벗어난 목록 조회는 차단한다', () async {
    final result = await GetFeedPostsScenario(repository)(limit: 51, offset: 0);

    expect(result, isA<Err<List<FeedPost>>>());
    expect((result as Err<List<FeedPost>>).failure, isA<ValidationFailure>());
    verifyNever(
      () => repository.getFeedPosts(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    );
  });

  test('단건 조회는 게시물 식별자가 있어야 한다', () async {
    final result = await GetFeedPostScenario(repository)('  ');

    expect(result, isA<Err<FeedPost>>());
    verifyNever(() => repository.getFeedPost(any()));
  });

  test('단건 조회를 저장소에 위임한다', () async {
    final post = _post();
    when(
      () => repository.getFeedPost('post-id'),
    ).thenAnswer((_) async => Ok(post));

    final result = await GetFeedPostScenario(repository)('post-id');

    expect((result as Ok<FeedPost>).value, post);
    verify(() => repository.getFeedPost('post-id')).called(1);
  });

  test('수정은 본문을 정리해 저장소에 전달한다', () async {
    final post = FeedPost(
      id: 'post-id',
      authorId: 'author-id',
      content: '수정된 기록',
      createdAt: DateTime.utc(2026, 8, 22, 9),
      updatedAt: DateTime.utc(2026, 8, 22, 10),
    );
    when(
      () => repository.updateFeedPost(any(), any()),
    ).thenAnswer((_) async => Ok(post));

    final result = await UpdateFeedPostScenario(repository)(
      'post-id',
      const FeedPostUpdate(content: ' 수정된 기록 '),
    );

    expect((result as Ok<FeedPost>).value, post);
    verify(
      () => repository.updateFeedPost(
        'post-id',
        const FeedPostUpdate(content: '수정된 기록'),
      ),
    ).called(1);
  });

  test('삭제는 게시물 식별자가 있어야 한다', () async {
    final result = await DeleteFeedPostScenario(repository)('');

    expect(result, isA<Err<void>>());
    verifyNever(() => repository.deleteFeedPost(any()));
  });

  test('삭제를 저장소에 위임한다', () async {
    when(
      () => repository.deleteFeedPost('post-id'),
    ).thenAnswer((_) async => const Ok(null));

    final result = await DeleteFeedPostScenario(repository)('post-id');

    expect(result, isA<Ok<void>>());
    verify(() => repository.deleteFeedPost('post-id')).called(1);
  });
}

FeedPost _post() => FeedPost(
  id: 'post-id',
  authorId: 'author-id',
  content: '기록',
  createdAt: DateTime.utc(2026, 8, 22, 9),
  updatedAt: DateTime.utc(2026, 8, 22, 10),
);
