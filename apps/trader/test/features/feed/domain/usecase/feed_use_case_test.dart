import 'package:core/core.dart';
import 'package:daylog/features/feed/domain/entity/feed_post.dart';
import 'package:daylog/features/feed/domain/repository/feed_repository.dart';
import 'package:daylog/features/feed/domain/usecase/feed_use_case.dart';
import 'package:daylog/features/feed/domain/entity/feed_source.dart';
import 'package:feature_post/feature_post.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFeedRepository extends Mock implements FeedRepository {}

class _MockPostUseCase extends Mock implements PostUseCase {}

Post _post(String id) => Post(
  id: id,
  authorId: 'me',
  content: '기록 $id',
  createdAt: DateTime.utc(2026, 9, 9, 9),
  updatedAt: DateTime.utc(2026, 9, 9, 9),
);

void main() {
  setUpAll(() => registerFallbackValue(FeedSource.all));

  late _MockFeedRepository repository;
  late _MockPostUseCase postUseCase;

  setUp(() {
    repository = _MockFeedRepository();
    postUseCase = _MockPostUseCase();
    when(
      () => postUseCase.createdPosts,
    ).thenAnswer((_) => const Stream<Post>.empty());
    when(
      () => repository.getPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FeedPost>(items: [])));
  });

  test('작성자 필터를 시나리오를 거쳐 저장소까지 그대로 넘긴다', () async {
    await DefaultFeedUseCase(
      repository,
      postUseCase,
    ).getFeedPosts(limit: 10, cursor: 'cursor-token', authorId: 'author-id');

    verify(
      () => repository.getPosts(
        limit: 10,
        cursor: 'cursor-token',
        authorId: 'author-id',
        source: FeedSource.all,
      ),
    ).called(1);
  });

  test('작성자를 지정하지 않으면 필터 없이 전체 피드를 읽는다', () async {
    await DefaultFeedUseCase(repository, postUseCase).getFeedPosts();

    verify(
      () => repository.getPosts(
        limit: 20,
        cursor: null,
        authorId: null,
        source: FeedSource.all,
      ),
    ).called(1);
  });

  test('게시물 생성 이벤트를 post feature 에서 그대로 흘려보낸다', () async {
    when(
      () => postUseCase.createdPosts,
    ).thenAnswer((_) => Stream<Post>.value(_post('1')));

    final created = await DefaultFeedUseCase(
      repository,
      postUseCase,
    ).createdPosts.toList();

    expect(created.single.id, '1');
  });
}
