import 'package:daylog/features/feed/data/dto/feed_post_dto.dart';
import 'package:daylog/features/feed/data/mapper/feed_post_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FeedPostDto를 domain FeedPost로 변환한다', () {
    final createdAt = DateTime.utc(2026, 8, 22, 9);
    final updatedAt = DateTime.utc(2026, 8, 22, 10);
    final dto = FeedPostDto(
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
}
