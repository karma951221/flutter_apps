import 'package:daylog/features/feed/data/dto/feed_post_dto.dart';
import 'package:daylog/features/feed/data/mapper/feed_post_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

final _dto = FeedPostDto(
  id: 'post-id',
  authorId: 'author-id',
  content: '오늘의 기록',
  createdAt: DateTime.utc(2026, 8, 22, 9),
  updatedAt: DateTime.utc(2026, 8, 22, 10),
);

void main() {
  test('FeedPostDto를 post domain 의 Post로 변환한다', () {
    final post = _dto.toEntity();

    expect(post.id, 'post-id');
    expect(post.authorId, 'author-id');
    expect(post.content, '오늘의 기록');
    expect(post.createdAt, DateTime.utc(2026, 8, 22, 9));
    expect(post.updatedAt, DateTime.utc(2026, 8, 22, 10));
  });

  test('커서는 정렬 기준인 created_at 과 id 로 만든다', () {
    final cursor = _dto.toCursor();

    expect(cursor.createdAt, _dto.createdAt);
    expect(cursor.id, _dto.id);
  });
}
