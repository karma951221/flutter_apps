import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/feed/domain/entity/feed_post.dart';
import 'package:daylog/features/feed/domain/entity/feed_post_draft.dart';
import 'package:daylog/features/feed/domain/repository/feed_repository.dart';
import 'package:daylog/features/feed/domain/usecase/scenario/create_feed_post_scenario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late _MockFeedRepository repository;
  late CreateFeedPostScenario scenario;

  setUpAll(() {
    registerFallbackValue(const FeedPostDraft(content: 'fallback'));
  });

  setUp(() {
    repository = _MockFeedRepository();
    scenario = CreateFeedPostScenario(repository);
  });

  test('공백뿐인 게시물은 저장하지 않는다', () async {
    final result = await scenario(const FeedPostDraft(content: '  '));

    expect(result, isA<Err<FeedPost>>());
    expect((result as Err<FeedPost>).failure, isA<ValidationFailure>());
    verifyNever(() => repository.createFeedPost(any()));
  });

  test('본문 양끝 공백을 제거해서 저장한다', () async {
    final post = FeedPost(
      id: 'post-id',
      authorId: 'author-id',
      content: '오늘의 기록',
      createdAt: DateTime.utc(2026, 8, 22),
      updatedAt: DateTime.utc(2026, 8, 22),
    );
    when(
      () => repository.createFeedPost(any()),
    ).thenAnswer((_) async => Ok(post));

    final result = await scenario(const FeedPostDraft(content: ' 오늘의 기록 '));

    expect(result, isA<Ok<FeedPost>>());
    expect((result as Ok<FeedPost>).value, post);
    verify(
      () => repository.createFeedPost(const FeedPostDraft(content: '오늘의 기록')),
    ).called(1);
  });

  test('500자를 초과하면 저장하지 않는다', () async {
    final result = await scenario(FeedPostDraft(content: '가' * 501));

    expect(result, isA<Err<FeedPost>>());
    verifyNever(() => repository.createFeedPost(any()));
  });
}
