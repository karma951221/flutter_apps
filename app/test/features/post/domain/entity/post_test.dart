import 'package:daylog/features/post/domain/entity/post.dart';
import 'package:daylog/features/post/domain/entity/post_image.dart';
import 'package:daylog/features/trade/domain/entity/trade_result_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final post = Post(
    id: 'post-1',
    authorId: 'user-1',
    content: '기록',
    createdAt: DateTime.utc(2026, 9, 9, 1),
    updatedAt: DateTime.utc(2026, 9, 9, 2),
    images: const [
      PostImage(
        id: 'image-1',
        url: 'https://example.test/1.jpg',
        width: 10,
        height: 20,
        sortOrder: 0,
      ),
    ],
    tradeResult: TradeResultSummary(
      sessionId: 'session-1',
      symbol: 'BTCUSDT',
      startDay: DateTime(2026, 1, 1),
      endDay: DateTime(2026, 3, 1),
      returnPct: 1.2,
      buyHoldReturnPct: 0.3,
      maxDrawdownPct: 2.4,
      tradeCount: 3,
    ),
  );

  test('이미지와 판 요약을 포함한 Post를 Map으로 왕복한다', () {
    expect(Post.fromMap(post.toMap()), post);
  });

  test('중첩 이미지 모양이 어긋나면 null이다', () {
    final raw = post.toMap()
      ..['images'] = [
        {'id': 'image-1'},
      ];

    expect(Post.fromMap(raw), isNull);
  });

  test('중첩 판 요약 모양이 어긋나면 null이다', () {
    final raw = post.toMap()..['trade_result'] = {'session_id': 1};

    expect(Post.fromMap(raw), isNull);
  });

  test('Post 모양이 아니면 null이다', () {
    expect(Post.fromMap(null), isNull);
    expect(Post.fromMap({'id': 'post-1'}), isNull);
  });
}
