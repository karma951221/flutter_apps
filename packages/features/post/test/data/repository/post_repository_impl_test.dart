import 'package:core/core.dart';
import 'package:feature_post/feature_post.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostDataSource extends Mock implements PostDataSource {}

final _dto = PostDto(
  id: 'post-id',
  authorId: 'author-id',
  content: '오늘의 기록',
  createdAt: DateTime.utc(2026, 8, 22, 9),
  updatedAt: DateTime.utc(2026, 8, 22, 10),
);

void main() {
  late _MockPostDataSource dataSource;
  late PostRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(const PostDraft(content: 'fallback')));

  setUp(() {
    dataSource = _MockPostDataSource();
    repository = PostRepositoryImpl(dataSource);
  });

  test('작성 결과 DTO를 domain Post로 변환한다', () async {
    when(() => dataSource.createPost(any())).thenAnswer((_) async => _dto);

    final result = await repository.createPost(
      const PostDraft(content: '오늘의 기록'),
    );

    expect((result as Ok).value.id, 'post-id');
  });

  test('미인증(null)은 인증 실패로 옮긴다', () async {
    when(() => dataSource.createPost(any())).thenAnswer((_) async => null);

    final result = await repository.createPost(
      const PostDraft(content: '오늘의 기록'),
    );

    expect((result as Err).failure, isA<AuthFailure>());
  });

  test('소프트 삭제 성공은 Ok로 돌려준다', () async {
    when(() => dataSource.deletePost('post-id')).thenAnswer((_) async => true);

    expect(await repository.deletePost('post-id'), isA<Ok<void>>());
  });

  test('삭제 대상이 없으면 notFound로 옮긴다', () async {
    // soft_delete_post 는 이미 삭제됐을 때와 남의 글일 때 모두 false 를 준다.
    // 둘을 구분해 알려주면 남의 게시물 존재 여부가 새어나간다.
    when(() => dataSource.deletePost('post-id')).thenAnswer((_) async => false);

    final result = await repository.deletePost('post-id');

    expect((result as Err).failure, isA<NotFoundFailure>());
  });

  test('삭제 시 미인증(null)은 인증 실패로 옮긴다', () async {
    when(() => dataSource.deletePost('post-id')).thenAnswer((_) async => null);

    final result = await repository.deletePost('post-id');

    expect((result as Err).failure, isA<AuthFailure>());
  });
}
