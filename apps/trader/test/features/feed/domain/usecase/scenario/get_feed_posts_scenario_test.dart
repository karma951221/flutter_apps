import 'package:core/core.dart';
import 'package:daylog/features/feed/domain/entity/feed_post.dart';
import 'package:daylog/features/feed/domain/repository/feed_repository.dart';
import 'package:daylog/features/feed/domain/usecase/scenario/get_feed_posts_scenario.dart';
import 'package:daylog/features/feed/domain/entity/feed_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  setUpAll(() => registerFallbackValue(FeedSource.all));

  late _MockFeedRepository repository;

  setUp(() => repository = _MockFeedRepository());

  test('첫 페이지는 커서 없이 요청한다', () async {
    when(
      () =>
          repository.getPosts(limit: 20, cursor: null, source: FeedSource.all),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));

    final result = await GetFeedPostsScenario(repository)(limit: 20);

    expect(result, isA<Ok<CursorPage<FeedPost>>>());
    verify(
      () =>
          repository.getPosts(limit: 20, cursor: null, source: FeedSource.all),
    ).called(1);
  });

  test('받은 커서를 그대로 넘긴다', () async {
    when(
      () => repository.getPosts(
        limit: 20,
        cursor: 'cursor-token',
        source: FeedSource.all,
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));

    await GetFeedPostsScenario(repository)(limit: 20, cursor: 'cursor-token');

    verify(
      () => repository.getPosts(
        limit: 20,
        cursor: 'cursor-token',
        source: FeedSource.all,
      ),
    ).called(1);
  });

  test('허용 범위를 벗어난 개수는 저장소를 호출하지 않는다', () async {
    for (final limit in [0, -1, GetFeedPostsScenario.maxPageSize + 1]) {
      final result = await GetFeedPostsScenario(repository)(limit: limit);

      expect((result as Err).failure, isA<ValidationFailure>());
    }

    verifyNever(
      () => repository.getPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        source: any(named: 'source'),
      ),
    );
  });

  test('공백뿐인 커서는 거부한다', () async {
    final result = await GetFeedPostsScenario(repository)(
      limit: 20,
      cursor: '   ',
    );

    expect((result as Err).failure, isA<ValidationFailure>());
    verifyNever(
      () => repository.getPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        source: any(named: 'source'),
      ),
    );
  });

  test('작성자 필터를 그대로 저장소에 넘긴다', () async {
    when(
      () => repository.getPosts(
        limit: 20,
        cursor: null,
        authorId: 'author-id',
        source: FeedSource.all,
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));

    await GetFeedPostsScenario(repository)(limit: 20, authorId: 'author-id');

    verify(
      () => repository.getPosts(
        limit: 20,
        cursor: null,
        authorId: 'author-id',
        source: FeedSource.all,
      ),
    ).called(1);
  });

  test('작성자를 지정하지 않으면 필터 없이 요청한다', () async {
    when(
      () => repository.getPosts(
        limit: 20,
        cursor: null,
        authorId: null,
        source: FeedSource.all,
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));

    await GetFeedPostsScenario(repository)(limit: 20);

    verify(
      () => repository.getPosts(
        limit: 20,
        cursor: null,
        authorId: null,
        source: FeedSource.all,
      ),
    ).called(1);
  });

  test('커서와 작성자 필터를 함께 넘긴다', () async {
    when(
      () => repository.getPosts(
        limit: 20,
        cursor: 'cursor-token',
        authorId: 'author-id',
        source: FeedSource.all,
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));

    await GetFeedPostsScenario(repository)(
      limit: 20,
      cursor: 'cursor-token',
      authorId: 'author-id',
    );

    verify(
      () => repository.getPosts(
        limit: 20,
        cursor: 'cursor-token',
        authorId: 'author-id',
        source: FeedSource.all,
      ),
    ).called(1);
  });
}
