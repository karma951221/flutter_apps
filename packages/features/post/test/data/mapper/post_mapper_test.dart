import 'package:feature_post/feature_post.dart';
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

  test('임베드한 trade_result 를 판 결과 요약으로 옮긴다', () {
    // 임베드 별칭이 피드 뷰의 jsonb 와 같은 키를 쓰므로 두 DTO 가 같은 JSON 을
    // 읽는다. 키가 어긋나면 카드가 조용히 사라지는 자리라 JSON 으로 확인한다.
    final post = PostDto.fromJson({
      'id': 'post-id',
      'author_id': 'author-id',
      'content': '본문',
      'created_at': '2026-09-08T09:00:00.000Z',
      'updated_at': '2026-09-08T09:00:00.000Z',
      'trade_result': {
        'session_id': 'session-1',
        'symbol': 'BTCUSDT',
        'start_day': '2024-01-01',
        'end_day': '2024-04-29',
        'return_pct': 12.34,
        'buy_hold_return_pct': 5.1,
        'max_drawdown_pct': 8.2,
        'trade_count': 7,
      },
    }).toEntity();

    final result = post.tradeResult!;
    expect(result.sessionId, 'session-1');
    expect(result.symbol, 'BTCUSDT');
    expect(result.displaySymbol, 'BTC');
    expect(result.startDay, DateTime(2024, 1, 1));
    expect(result.endDay, DateTime(2024, 4, 29));
    expect(result.returnPct, 12.34);
    expect(result.buyHoldReturnPct, 5.1);
    expect(result.maxDrawdownPct, 8.2);
    expect(result.tradeCount, 7);
    expect(result.beatBuyHold, isTrue);
  });

  test('판을 붙이지 않은 게시물은 결과가 null 이다', () {
    // 임베드는 붙은 판이 없으면 키 자체를 null 로 내린다.
    final dto = PostDto.fromJson({
      'id': 'post-id',
      'author_id': 'author-id',
      'content': '본문',
      'created_at': '2026-09-08T09:00:00.000Z',
      'updated_at': '2026-09-08T09:00:00.000Z',
      'trade_result': null,
    });

    expect(dto.tradeResult, isNull);
    expect(dto.toEntity().tradeResult, isNull);
  });
}
