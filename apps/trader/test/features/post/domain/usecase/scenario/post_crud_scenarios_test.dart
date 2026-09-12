import 'package:core/core.dart';
import 'package:daylog/features/post/domain/entity/post.dart';
import 'package:daylog/features/post/domain/entity/post_update.dart';
import 'package:daylog/features/post/domain/repository/post_repository.dart';
import 'package:daylog/features/post/domain/usecase/scenario/delete_post_scenario.dart';
import 'package:daylog/features/post/domain/usecase/scenario/get_post_scenario.dart';
import 'package:daylog/features/post/domain/usecase/scenario/update_post_scenario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostRepository extends Mock implements PostRepository {}

final _post = Post(
  id: 'post-id',
  authorId: 'author-id',
  content: '오늘의 기록',
  createdAt: DateTime.utc(2026, 8, 22, 9),
  updatedAt: DateTime.utc(2026, 8, 22, 10),
);

void main() {
  late _MockPostRepository repository;

  setUpAll(() => registerFallbackValue(const PostUpdate(content: 'fallback')));

  setUp(() => repository = _MockPostRepository());

  group('단건 조회', () {
    test('식별자를 저장소에 위임한다', () async {
      when(
        () => repository.getPost('post-id'),
      ).thenAnswer((_) async => Ok(_post));

      final result = await GetPostScenario(repository)('post-id');

      expect(result, isA<Ok<Post>>());
      verify(() => repository.getPost('post-id')).called(1);
    });

    test('빈 식별자는 저장소를 호출하지 않는다', () async {
      final result = await GetPostScenario(repository)('  ');

      expect((result as Err<Post>).failure, isA<ValidationFailure>());
      verifyNever(() => repository.getPost(any()));
    });
  });

  group('수정', () {
    test('공백을 제거한 본문으로 수정을 요청한다', () async {
      when(
        () => repository.updatePost(any(), any()),
      ).thenAnswer((_) async => Ok(_post));

      final result = await UpdatePostScenario(repository)(
        'post-id',
        const PostUpdate(content: '  고친 내용  '),
      );

      expect(result, isA<Ok<Post>>());
      final captured =
          verify(
                () => repository.updatePost('post-id', captureAny()),
              ).captured.single
              as PostUpdate;
      expect(captured.content, '고친 내용');
    });

    test('빈 본문으로는 수정하지 않는다', () async {
      final result = await UpdatePostScenario(repository)(
        'post-id',
        const PostUpdate(content: '   '),
      );

      expect((result as Err<Post>).failure, isA<ValidationFailure>());
      verifyNever(() => repository.updatePost(any(), any()));
    });
  });

  group('삭제', () {
    test('식별자를 저장소에 위임한다', () async {
      when(
        () => repository.deletePost('post-id'),
      ).thenAnswer((_) async => const Ok(null));

      final result = await DeletePostScenario(repository)('post-id');

      expect(result, isA<Ok<void>>());
      verify(() => repository.deletePost('post-id')).called(1);
    });

    test('빈 식별자는 저장소를 호출하지 않는다', () async {
      final result = await DeletePostScenario(repository)('');

      expect((result as Err<void>).failure, isA<ValidationFailure>());
      verifyNever(() => repository.deletePost(any()));
    });
  });
}
