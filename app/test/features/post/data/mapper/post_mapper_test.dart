import 'package:daylog/features/post/data/dto/post_dto.dart';
import 'package:daylog/features/post/data/mapper/post_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PostDto를 domain Post로 손실 없이 변환한다', () {
    final createdAt = DateTime.utc(2026, 8, 22, 9);
    final updatedAt = DateTime.utc(2026, 8, 22, 10);
    final dto = PostDto(
      id: 'post-id',
      authorId: 'author-id',
      content: '오늘의 기록',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    final post = dto.toEntity();

    expect(post.id, 'post-id');
    expect(post.authorId, 'author-id');
    expect(post.content, '오늘의 기록');
    expect(post.createdAt, createdAt);
    expect(post.updatedAt, updatedAt);
  });

  test('snake_case 컬럼명을 그대로 읽는다', () {
    final dto = PostDto.fromJson({
      'id': 'post-id',
      'author_id': 'author-id',
      'content': '본문',
      'created_at': '2026-08-22T09:00:00.000Z',
      'updated_at': '2026-08-22T10:00:00.000Z',
    });

    expect(dto.authorId, 'author-id');
    expect(dto.createdAt, DateTime.utc(2026, 8, 22, 9));
  });
}
