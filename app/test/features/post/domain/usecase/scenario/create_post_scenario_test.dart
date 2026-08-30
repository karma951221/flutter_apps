import 'dart:typed_data';

import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/post/domain/entity/post.dart';
import 'package:daylog/features/post/domain/entity/post_draft.dart';
import 'package:daylog/features/post/domain/entity/post_image_draft.dart';
import 'package:daylog/features/post/domain/post_policy.dart';
import 'package:daylog/features/post/domain/repository/post_repository.dart';
import 'package:daylog/features/post/domain/usecase/scenario/create_post_scenario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostRepository extends Mock implements PostRepository {}

final _post = Post(
  id: 'post-id',
  authorId: 'author-id',
  content: '오늘의 기록',
  createdAt: DateTime.utc(2026, 8, 22, 9),
  updatedAt: DateTime.utc(2026, 8, 22, 9),
);

PostImageDraft _image(int seed) => PostImageDraft(
  bytes: Uint8List.fromList([seed]),
  width: 100 + seed,
  height: 200 + seed,
  contentType: 'image/webp',
  extension: 'webp',
);

void main() {
  late _MockPostRepository repository;

  setUpAll(() => registerFallbackValue(const PostDraft(content: 'fallback')));

  setUp(() => repository = _MockPostRepository());

  test('앞뒤 공백을 제거한 본문으로 저장을 요청한다', () async {
    when(() => repository.createPost(any())).thenAnswer((_) async => Ok(_post));

    final result = await CreatePostScenario(repository)(
      const PostDraft(content: '  오늘의 기록  '),
    );

    expect(result, isA<Ok<Post>>());
    final captured =
        verify(() => repository.createPost(captureAny())).captured.single
            as PostDraft;
    expect(captured.content, '오늘의 기록');
  });

  test('공백뿐인 본문은 저장하지 않는다', () async {
    final result = await CreatePostScenario(repository)(
      const PostDraft(content: '   '),
    );

    expect((result as Err<Post>).failure, isA<ValidationFailure>());
    verifyNever(() => repository.createPost(any()));
  });

  test('DB CHECK 제약과 같은 길이에서 막는다', () async {
    final tooLong = 'ㄱ' * (PostPolicy.maxContentLength + 1);

    final result = await CreatePostScenario(repository)(
      PostDraft(content: tooLong),
    );

    expect((result as Err<Post>).failure, isA<ValidationFailure>());
    verifyNever(() => repository.createPost(any()));
  });

  test('최대 길이는 허용한다', () async {
    when(() => repository.createPost(any())).thenAnswer((_) async => Ok(_post));

    final result = await CreatePostScenario(repository)(
      PostDraft(content: 'ㄱ' * PostPolicy.maxContentLength),
    );

    expect(result, isA<Ok<Post>>());
  });

  test('본문을 정규화해도 첨부 이미지는 그대로 전달한다', () async {
    when(() => repository.createPost(any())).thenAnswer((_) async => Ok(_post));
    final images = [_image(1), _image(2)];

    await CreatePostScenario(repository)(
      PostDraft(content: '  오늘의 기록  ', images: images),
    );

    final captured =
        verify(() => repository.createPost(captureAny())).captured.single
            as PostDraft;
    expect(captured.content, '오늘의 기록');
    expect(captured.images, hasLength(2));
    expect(captured.images.map((image) => image.width), [101, 102]);
    expect(captured.images.map((image) => image.height), [201, 202]);
    expect(captured.images.map((image) => image.bytes.single), [1, 2]);
  });

  test('최대 장수까지는 허용한다', () async {
    when(() => repository.createPost(any())).thenAnswer((_) async => Ok(_post));

    final result = await CreatePostScenario(repository)(
      PostDraft(
        content: '오늘의 기록',
        images: List.generate(PostPolicy.maxImageCount, _image),
      ),
    );

    expect(result, isA<Ok<Post>>());
  });

  test('최대 장수를 넘는 첨부는 저장하지 않는다', () async {
    final result = await CreatePostScenario(repository)(
      PostDraft(
        content: '오늘의 기록',
        images: List.generate(PostPolicy.maxImageCount + 1, _image),
      ),
    );

    expect((result as Err<Post>).failure, isA<ValidationFailure>());
    verifyNever(() => repository.createPost(any()));
  });
}
