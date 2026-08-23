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

  test('post_images 조인 결과를 받은 순서대로 PostImage 로 옮긴다', () {
    // 정렬은 데이터 원천이 sort_order 로 하고, 변환은 순서를 흐트러뜨리지
    // 않는 것만 책임진다.
    final post = PostDto.fromJson({
      'id': 'post-id',
      'author_id': 'author-id',
      'content': '본문',
      'created_at': '2026-08-22T09:00:00.000Z',
      'updated_at': '2026-08-22T10:00:00.000Z',
      'post_images': [
        {
          'id': 'image-1',
          'url': 'https://example.test/1.webp',
          'width': 1080,
          'height': 810,
          'sort_order': 0,
        },
        {
          'id': 'image-2',
          'url': 'https://example.test/2.webp',
          'width': 720,
          'height': 720,
          'sort_order': 1,
        },
      ],
    }).toEntity();

    expect(post.images.map((image) => image.id), ['image-1', 'image-2']);
    expect(post.images.first.url, 'https://example.test/1.webp');
    expect(post.images.first.width, 1080);
    expect(post.images.first.height, 810);
    expect(post.images.map((image) => image.sortOrder), [0, 1]);
  });

  test('이미지가 없는 게시물은 빈 목록으로 읽는다', () {
    // 조인 결과가 통째로 빠져도(=키 자체가 없어도) null 이 아니라 빈 목록이어야
    // 화면이 이미지 유무만 보고 그린다.
    final dto = PostDto.fromJson({
      'id': 'post-id',
      'author_id': 'author-id',
      'content': '본문',
      'created_at': '2026-08-22T09:00:00.000Z',
      'updated_at': '2026-08-22T10:00:00.000Z',
    });

    expect(dto.images, isEmpty);
    expect(dto.toEntity().images, isEmpty);
  });
}
