import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/post/domain/entity/post.dart';
import 'package:daylog/features/post/domain/entity/post_draft.dart';
import 'package:daylog/features/post/domain/entity/post_image_draft.dart';
import 'package:daylog/features/post/domain/entity/post_update.dart';
import 'package:daylog/features/post/domain/post_policy.dart';
import 'package:daylog/features/post/domain/usecase/post_use_case.dart';
import 'package:daylog/features/post/presentation/cubit/post_cubit.dart';
import 'package:daylog/features/post/presentation/cubit/post_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostUseCase extends Mock implements PostUseCase {}

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
  late _MockPostUseCase useCase;

  setUpAll(() {
    registerFallbackValue(const PostDraft(content: 'fallback'));
    registerFallbackValue(const PostUpdate(content: 'fallback'));
  });

  setUp(() => useCase = _MockPostUseCase());

  blocTest<PostCubit, PostState>(
    '작성 중에는 제출 상태를 켜고 끝나면 되돌린다',
    setUp: () => when(
      () => useCase.createPost(any()),
    ).thenAnswer((_) async => Ok(_post)),
    build: () => PostCubit(useCase),
    act: (cubit) => cubit.create('오늘의 기록'),
    expect: () => [const PostState(isSubmitting: true), const PostState()],
  );

  blocTest<PostCubit, PostState>(
    '실패는 상태에 남긴다',
    setUp: () => when(
      () => useCase.createPost(any()),
    ).thenAnswer((_) async => const Err(Failure.network())),
    build: () => PostCubit(useCase),
    act: (cubit) => cubit.create('오늘의 기록'),
    expect: () => [
      const PostState(isSubmitting: true),
      const PostState(failure: Failure.network()),
    ],
  );

  test('제출 중 재요청은 usecase 를 호출하지 않는다', () async {
    when(() => useCase.createPost(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return Ok(_post);
    });
    final cubit = PostCubit(useCase);

    final first = cubit.create('첫 요청');
    final second = await cubit.create('중복 요청');
    await first;

    expect((second as Err).failure, isA<ValidationFailure>());
    verify(() => useCase.createPost(any())).called(1);
    await cubit.close();
  });

  test('수정과 삭제도 usecase 에 위임한다', () async {
    when(
      () => useCase.updatePost(any(), any()),
    ).thenAnswer((_) async => Ok(_post));
    when(
      () => useCase.deletePost(any()),
    ).thenAnswer((_) async => const Ok(null));
    final cubit = PostCubit(useCase);

    await cubit.update('post-id', '고친 내용');
    await cubit.delete('post-id');

    final update =
        verify(
              () => useCase.updatePost('post-id', captureAny()),
            ).captured.single
            as PostUpdate;
    expect(update.content, '고친 내용');
    verify(() => useCase.deletePost('post-id')).called(1);
    await cubit.close();
  });

  test('첨부한 이미지를 그대로 작성 usecase 에 넘긴다', () async {
    when(() => useCase.createPost(any())).thenAnswer((_) async => Ok(_post));
    final cubit = PostCubit(useCase);
    final images = List.generate(PostPolicy.maxImageCount, _image);

    await cubit.create('오늘의 기록', images: images);

    final draft =
        verify(() => useCase.createPost(captureAny())).captured.single
            as PostDraft;
    expect(draft.content, '오늘의 기록');
    expect(draft.images, images);
    await cubit.close();
  });

  test('공유할 판 id 를 draft 에 실어 usecase 로 넘긴다', () async {
    when(() => useCase.createPost(any())).thenAnswer((_) async => Ok(_post));
    final cubit = PostCubit(useCase);

    await cubit.create('오늘의 판', tradeSessionId: 'session-1');

    final draft =
        verify(() => useCase.createPost(captureAny())).captured.single
            as PostDraft;
    expect(draft.tradeSessionId, 'session-1');
    await cubit.close();
  });

  test('판을 붙이지 않으면 draft 의 판 id 는 null 이다', () async {
    when(() => useCase.createPost(any())).thenAnswer((_) async => Ok(_post));
    final cubit = PostCubit(useCase);

    await cubit.create('오늘의 기록');

    final draft =
        verify(() => useCase.createPost(captureAny())).captured.single
            as PostDraft;
    expect(draft.tradeSessionId, isNull);
    await cubit.close();
  });
}
