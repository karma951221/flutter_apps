import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/pagination/cursor_page.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/feed/domain/repository/feed_repository.dart';
import 'package:daylog/features/feed/domain/usecase/scenario/get_feed_posts_scenario.dart';
import 'package:daylog/features/post/domain/entity/post.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late _MockFeedRepository repository;

  setUp(() => repository = _MockFeedRepository());

  test('첫 페이지는 커서 없이 요청한다', () async {
    when(
      () => repository.getPosts(limit: 20, cursor: null),
    ).thenAnswer((_) async => const Ok(CursorPage<Post>(items: [])));

    final result = await GetFeedPostsScenario(repository)(limit: 20);

    expect(result, isA<Ok<CursorPage<Post>>>());
    verify(() => repository.getPosts(limit: 20, cursor: null)).called(1);
  });

  test('받은 커서를 그대로 넘긴다', () async {
    when(
      () => repository.getPosts(limit: 20, cursor: 'cursor-token'),
    ).thenAnswer((_) async => const Ok(CursorPage<Post>(items: [])));

    await GetFeedPostsScenario(repository)(limit: 20, cursor: 'cursor-token');

    verify(
      () => repository.getPosts(limit: 20, cursor: 'cursor-token'),
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
      ),
    );
  });
}
