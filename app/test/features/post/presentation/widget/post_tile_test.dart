import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/post/domain/entity/post.dart';
import 'package:daylog/features/post/domain/entity/post_author.dart';
import 'package:daylog/features/post/presentation/widget/post_tile.dart';
import 'package:daylog/features/trade/domain/entity/trade_result_summary.dart';
import 'package:daylog/features/trade/presentation/widget/trade_result_card.dart';
import 'package:daylog/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _author = PostAuthor(id: 'author-1', nickname: '카르마');

Post _post({TradeResultSummary? tradeResult}) => Post(
  id: 'post-1',
  authorId: 'author-1',
  content: '오늘의 기록',
  createdAt: DateTime.utc(2026, 8, 23, 9),
  updatedAt: DateTime.utc(2026, 8, 23, 9),
  tradeResult: tradeResult,
);

TradeResultSummary _summary() => TradeResultSummary(
  sessionId: 'session-1',
  symbol: 'BTCUSDT',
  startDay: DateTime.utc(2021, 11),
  endDay: DateTime.utc(2022, 1, 29),
  returnPct: 12.34,
  buyHoldReturnPct: 3,
  maxDrawdownPct: 8,
  tradeCount: 4,
);

Future<void> _pump(
  WidgetTester tester, {
  required bool isMine,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
  VoidCallback? onReport,
  VoidCallback? onBlock,
  TradeResultSummary? tradeResult,
  ValueChanged<String>? onTradeResultTap,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    // ko 가 ARB template 언어라 원문이 곧 기대값이다 (계획서).
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: PostTile(
        post: _post(tradeResult: tradeResult),
        author: _author,
        isMine: isMine,
        onTap: () {},
        onEdit: onEdit,
        onDelete: onDelete,
        onReport: onReport,
        onBlock: onBlock,
        onTradeResultTap: onTradeResultTap,
      ),
    ),
  ),
);

void main() {
  testWidgets('내 글에는 수정 · 삭제가 뜨고 신고가 없다', (tester) async {
    await _pump(tester, isMine: true, onEdit: () {}, onDelete: () {});

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('수정'), findsOneWidget);
    expect(find.text('삭제'), findsOneWidget);
    expect(find.text('신고'), findsNothing);
  });

  testWidgets('남의 글에는 신고 · 차단이 뜨고 수정 · 삭제가 없다', (tester) async {
    await _pump(tester, isMine: false, onReport: () {}, onBlock: () {});

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('신고'), findsOneWidget);
    expect(find.text('이 사용자 차단'), findsOneWidget);
    expect(find.text('수정'), findsNothing);
    expect(find.text('삭제'), findsNothing);
  });

  testWidgets('신고를 고르면 onReport 가 불린다', (tester) async {
    var reported = false;
    await _pump(tester, isMine: false, onReport: () => reported = true);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('신고'));
    await tester.pumpAndSettle();

    expect(reported, isTrue);
  });

  testWidgets('콜백이 모두 null 이면 메뉴가 안 그려진다', (tester) async {
    await _pump(tester, isMine: false);

    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('내 글이면 onReport · onBlock 이 있어도 신고 · 차단은 뜨지 않는다', (tester) async {
    // isMine 과 onReport/onBlock 이 어긋난 호출부(버그 있는 콜러)를 가정한
    // 회귀 테스트. 신고·차단 항목이 뜨는지 여부는 콜백의 유무가 아니라
    // isMine 이 최종적으로 판정해야 한다 — CommentTile 과 같은 방어 규칙이다.
    await _pump(
      tester,
      isMine: true,
      onEdit: () {},
      onDelete: () {},
      onReport: () {},
      onBlock: () {},
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('신고'), findsNothing);
    expect(find.text('이 사용자 차단'), findsNothing);
    expect(find.text('수정'), findsOneWidget);
    expect(find.text('삭제'), findsOneWidget);
  });

  testWidgets('남의 글이면 onEdit · onDelete 가 있어도 수정 · 삭제는 뜨지 않는다', (tester) async {
    // isMine 과 콜백이 어긋난 호출부(버그 있는 콜러)를 가정한 회귀 테스트.
    // 수정 · 삭제가 뜨는지 여부는 콜백의 유무가 아니라 isMine 이 최종적으로
    // 판정해야 한다 — 신고 항목의 방어와 같은 방향이다.
    await _pump(
      tester,
      isMine: false,
      onEdit: () {},
      onDelete: () {},
      onReport: () {},
      onBlock: () {},
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('수정'), findsNothing);
    expect(find.text('삭제'), findsNothing);
    expect(find.text('신고'), findsOneWidget);
    expect(find.text('이 사용자 차단'), findsOneWidget);
  });

  testWidgets('차단을 고르면 onBlock 이 불린다', (tester) async {
    var blocked = false;
    await _pump(tester, isMine: false, onBlock: () => blocked = true);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 사용자 차단'));
    await tester.pumpAndSettle();

    expect(blocked, isTrue);
  });

  testWidgets('판 결과가 붙어 있으면 본문 아래에 카드를 그린다', (tester) async {
    await _pump(tester, isMine: false, tradeResult: _summary());

    expect(find.byType(TradeResultCard), findsOneWidget);
    expect(find.text('BTC · 2021-11-01 ~ 2022-01-29'), findsOneWidget);
    expect(find.text('+12.34%'), findsOneWidget);
  });

  testWidgets('판 결과가 없으면 카드를 그리지 않는다', (tester) async {
    await _pump(tester, isMine: false);

    expect(find.byType(TradeResultCard), findsNothing);
  });

  testWidgets('카드를 누르면 그 판 id 로 onTradeResultTap 이 불린다', (tester) async {
    String? tapped;
    await _pump(
      tester,
      isMine: false,
      tradeResult: _summary(),
      onTradeResultTap: (sessionId) => tapped = sessionId,
    );

    await tester.tap(find.byType(TradeResultCard));
    await tester.pumpAndSettle();

    expect(tapped, 'session-1');
  });

  testWidgets('onTradeResultTap 이 없으면 카드는 보이되 눌리지 않는다', (tester) async {
    // 카드 자신의 InkWell.onTap 은 콜백이 없으면 null 이어야 한다 — null 이면
    // 탭이 카드에서 소비되지 않고 타일 전체의 onTap(게시물 상세로 이동)으로
    // 그대로 넘어간다. 즉 여기서 확인하는 건 "카드가 자기 몫의 탭을 가로채지
    // 않는다"이지, 탭이 아무 효과도 없다는 뜻이 아니다.
    await _pump(tester, isMine: false, tradeResult: _summary());

    expect(find.byType(TradeResultCard), findsOneWidget);
    final inkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byType(TradeResultCard),
        matching: find.byType(InkWell),
      ),
    );
    expect(inkWell.onTap, isNull);
  });
}
