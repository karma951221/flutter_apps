import 'package:daylog/core/pagination/cursor_page.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/feed/domain/entity/feed_post.dart';
import 'package:daylog/features/feed/domain/repository/feed_repository.dart';
import 'package:daylog/features/feed/domain/usecase/feed_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late _MockFeedRepository repository;

  setUp(() {
    repository = _MockFeedRepository();
    when(
      () => repository.getPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));
  });

  test('작성자 필터를 시나리오를 거쳐 저장소까지 그대로 넘긴다', () async {
    await DefaultFeedUseCase(
      repository,
    ).getFeedPosts(limit: 10, cursor: 'cursor-token', authorId: 'author-id');

    verify(
      () => repository.getPosts(
        limit: 10,
        cursor: 'cursor-token',
        authorId: 'author-id',
      ),
    ).called(1);
  });

  test('작성자를 지정하지 않으면 필터 없이 전체 피드를 읽는다', () async {
    await DefaultFeedUseCase(repository).getFeedPosts();

    verify(
      () => repository.getPosts(limit: 20, cursor: null, authorId: null),
    ).called(1);
  });
}
