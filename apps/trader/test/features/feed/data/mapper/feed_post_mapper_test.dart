import 'package:daylog/features/feed/data/dto/feed_post_dto.dart';
import 'package:daylog/features/feed/data/mapper/feed_post_mapper.dart';
import 'package:feature_reaction/feature_reaction.dart';
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

  test('뷰가 내려준 반응 집계와 댓글 수를 항목에 담는다', () {
    final dto = FeedPostDto(
      id: 'post-1',
      authorId: 'author-1',
      content: '기록',
      createdAt: DateTime.utc(2026, 8, 23, 9),
      updatedAt: DateTime.utc(2026, 8, 23, 9),
      authorNickname: '카르마',
      reactionCounts: const {'like': 4, 'dislike': 1},
      myReaction: 'like',
      commentCount: 7,
    );

    final item = dto.toEntity();

    expect(item.reactions.countOf(ReactionType.like), 4);
    expect(item.reactions.countOf(ReactionType.dislike), 1);
    expect(item.reactions.mine, ReactionType.like);
    expect(item.commentCount, 7);
  });

  test('반응이 없으면 빈 집계이고 내 반응은 없다', () {
    final dto = FeedPostDto(
      id: 'post-1',
      authorId: 'author-1',
      content: '기록',
      createdAt: DateTime.utc(2026, 8, 23, 9),
      updatedAt: DateTime.utc(2026, 8, 23, 9),
      authorNickname: '카르마',
    );

    final item = dto.toEntity();

    expect(item.reactions.counts, isEmpty);
    expect(item.reactions.mine, isNull);
    expect(item.commentCount, 0);
  });

  test('뷰의 trade_result jsonb 를 판 결과 요약으로 옮긴다', () {
    final item = FeedPostDto.fromJson({
      'id': 'post-id',
      'author_id': 'author-id',
      'content': '오늘의 판',
      'created_at': '2026-09-08T09:00:00.000Z',
      'updated_at': '2026-09-08T09:00:00.000Z',
      'author_nickname': '카르마',
      'trade_result': {
        'session_id': 'session-1',
        'symbol': 'ETHUSDT',
        'start_day': '2024-02-01',
        'end_day': '2024-05-30',
        'return_pct': -5.1,
        'buy_hold_return_pct': -2.0,
        'max_drawdown_pct': 11.5,
        'trade_count': 3,
      },
    }).toEntity();

    final result = item.post.tradeResult!;
    expect(result.sessionId, 'session-1');
    expect(result.displaySymbol, 'ETH');
    expect(result.startDay, DateTime(2024, 2, 1));
    expect(result.endDay, DateTime(2024, 5, 30));
    expect(result.returnPct, -5.1);
    expect(result.buyHoldReturnPct, -2.0);
    expect(result.maxDrawdownPct, 11.5);
    expect(result.tradeCount, 3);
    expect(result.beatBuyHold, isFalse);
  });

  test('판이 없는 게시물은 결과가 null 이다', () {
    // 뷰의 lateral 이 0행이면 컬럼이 통째로 null 이다 (docs/schema.md §6).
    final dto = FeedPostDto.fromJson({
      'id': 'post-id',
      'author_id': 'author-id',
      'content': '오늘의 기록',
      'created_at': '2026-09-08T09:00:00.000Z',
      'updated_at': '2026-09-08T09:00:00.000Z',
      'author_nickname': '카르마',
      'trade_result': null,
    });

    expect(dto.tradeResult, isNull);
    expect(dto.toEntity().post.tradeResult, isNull);
    expect(_dto.toPost().tradeResult, isNull);
  });
}
