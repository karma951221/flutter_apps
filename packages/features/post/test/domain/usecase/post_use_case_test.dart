import 'package:core/core.dart';
import 'package:feature_post/feature_post.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostRepository extends Mock implements PostRepository {}

final _post = Post(
  id: 'post-id',
  authorId: 'author-id',
  content: '오늘의 기록',
  createdAt: DateTime.utc(2026, 9, 9, 9),
  updatedAt: DateTime.utc(2026, 9, 9, 9),
);

void main() {
  late _MockPostRepository repository;
  late DefaultPostUseCase useCase;

  setUpAll(() => registerFallbackValue(const PostDraft(content: 'fallback')));

  setUp(() {
    repository = _MockPostRepository();
    useCase = DefaultPostUseCase(repository);
  });

  tearDown(() => useCase.dispose());

  test('저장에 성공한 게시물을 생성 이벤트로 알린다', () async {
    when(() => repository.createPost(any())).thenAnswer((_) async => Ok(_post));
    final created = expectLater(
      useCase.createdPosts,
      emits(isA<Post>().having((post) => post.id, 'id', 'post-id')),
    );

    final result = await useCase.createPost(const PostDraft(content: '오늘의 기록'));

    expect(result, isA<Ok<Post>>());
    await created;
  });

  test('저장에 실패하면 아무것도 알리지 않는다', () async {
    when(() => repository.createPost(any())).thenAnswer(
      (_) async => const Err(
        Failure.network(
          message: '저장에 실패했습니다',
          failureCode: FailureCode.networkUnavailable,
        ),
      ),
    );
    final events = <Post>[];
    final subscription = useCase.createdPosts.listen(events.add);

    final result = await useCase.createPost(const PostDraft(content: '오늘의 기록'));
    // 이벤트는 마이크로태스크로 전달된다 — 한 바퀴 돌려 확인한다.
    await Future<void>.delayed(Duration.zero);

    expect(result, isA<Err<Post>>());
    expect(events, isEmpty);
    await subscription.cancel();
  });

  test('구독자가 여럿이어도 각자 받는다 — 피드 탭과 프로필 탭이 함께 듣는다', () async {
    when(() => repository.createPost(any())).thenAnswer((_) async => Ok(_post));
    final first = <Post>[];
    final second = <Post>[];
    final firstSubscription = useCase.createdPosts.listen(first.add);
    final secondSubscription = useCase.createdPosts.listen(second.add);

    await useCase.createPost(const PostDraft(content: '오늘의 기록'));
    await Future<void>.delayed(Duration.zero);

    expect(first.single.id, 'post-id');
    expect(second.single.id, 'post-id');
    await firstSubscription.cancel();
    await secondSubscription.cancel();
  });
}
