import 'package:daylog/features/feed/data/dto/feed_post_dto.dart';
import 'package:daylog/features/feed/data/mapper/feed_post_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

final _dto = FeedPostDto(
  id: 'post-id',
  authorId: 'author-id',
  content: '오늘의 기록',
  createdAt: DateTime.utc(2026, 8, 22, 9),
  updatedAt: DateTime.utc(2026, 8, 22, 10),
  authorNickname: '카르마',
  authorAvatarUrl: 'https://example.test/avatar.png',
);

void main() {
  test('FeedPostDto를 게시물과 작성자로 나눠 담는다', () {
    final item = _dto.toEntity();

    expect(item.id, 'post-id');
    expect(item.post.authorId, 'author-id');
    expect(item.post.content, '오늘의 기록');
    expect(item.post.createdAt, DateTime.utc(2026, 8, 22, 9));
    expect(item.post.updatedAt, DateTime.utc(2026, 8, 22, 10));
    expect(item.author.id, 'author-id');
    expect(item.author.nickname, '카르마');
    expect(item.author.avatarUrl, 'https://example.test/avatar.png');
  });

  test('아바타를 올리지 않은 작성자는 null 로 온다', () {
    final item = FeedPostDto(
      id: 'post-id',
      authorId: 'author-id',
      content: '오늘의 기록',
      createdAt: DateTime.utc(2026, 8, 22, 9),
      updatedAt: DateTime.utc(2026, 8, 22, 10),
      authorNickname: '카르마',
    ).toEntity();

    expect(item.author.avatarUrl, isNull);
    expect(item.author.nickname, '카르마');
  });

  test('뷰가 내려준 JSON 의 스네이크 케이스 컬럼을 읽는다', () {
    final dto = FeedPostDto.fromJson({
      'id': 'post-id',
      'author_id': 'author-id',
      'content': '오늘의 기록',
      'created_at': '2026-08-22T09:00:00.000Z',
      'updated_at': '2026-08-22T10:00:00.000Z',
      'author_nickname': '카르마',
      'author_avatar_url': null,
    });

    expect(dto.authorNickname, '카르마');
    expect(dto.authorAvatarUrl, isNull);
    expect(dto.createdAt, DateTime.utc(2026, 8, 22, 9));
  });

  test('커서는 정렬 기준인 created_at 과 id 로 만든다', () {
    final cursor = _dto.toCursor();

    expect(cursor.createdAt, _dto.createdAt);
    expect(cursor.id, _dto.id);
  });

  test('작성자가 달라도 게시물 변환 결과는 게시물만 담는다', () {
    // Post 는 작성자 프로필을 갖지 않는다. 조인 결과가 Post 로 새어 들어가면
    // 게시물 작성·수정 화면까지 프로필을 채워야 하는 구조가 된다.
    final post = _dto.toPost();

    expect(post.authorId, 'author-id');
    expect(post.content, '오늘의 기록');
  });
}
