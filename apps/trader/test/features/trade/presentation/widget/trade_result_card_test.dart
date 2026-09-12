import 'package:design_system/design_system.dart';
import 'package:daylog/features/trade/domain/entity/trade_result_summary.dart';
import 'package:daylog/features/trade/presentation/widget/trade_result_card.dart';
import 'package:l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TradeResultSummary _summary({
  double returnPct = 12.34,
  double buyHoldReturnPct = 3,
  double maxDrawdownPct = 8,
  int tradeCount = 4,
}) => TradeResultSummary(
  sessionId: 's1',
  symbol: 'BTCUSDT',
  startDay: DateTime.utc(2021, 11),
  endDay: DateTime.utc(2022, 1, 29),
  returnPct: returnPct,
  buyHoldReturnPct: buyHoldReturnPct,
  maxDrawdownPct: maxDrawdownPct,
  tradeCount: tradeCount,
);

Future<void> _pump(
  WidgetTester tester, {
  TradeResultSummary? summary,
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    // ko 가 ARB template 언어라 원문이 곧 기대값이다 (계획서).
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: TradeResultCard(summary: summary ?? _summary(), onTap: onTap),
    ),
  ),
);

Color? _returnColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  testWidgets('종목 · 기간 · 수익률과 보조 지표 한 줄을 보여준다', (tester) async {
    await _pump(tester);

    expect(find.text('BTC · 2021-11-01 ~ 2022-01-29'), findsOneWidget);
    expect(find.text('+12.34%'), findsOneWidget);
    // 보조 지표는 작은 글씨 한 줄이다. 낙폭은 아래로 내려간 폭이라 음수로 찍는다.
    expect(find.text('보유만 했을 때 +3.00% · 최대낙폭 −8.00% · 매매 4회'), findsOneWidget);
  });

  testWidgets('수익률은 방향에 따라 색이 다르고 0 은 색이 없다', (tester) async {
    await _pump(tester);
    expect(_returnColor(tester, '+12.34%'), AppColors.candleUp);

    await _pump(tester, summary: _summary(returnPct: -5.1));
    expect(_returnColor(tester, '−5.10%'), AppColors.candleDown);

    // 0 은 오르지도 내리지도 않았다. 기본 글자색 그대로 둔다.
    await _pump(tester, summary: _summary(returnPct: 0));
    expect(_returnColor(tester, '0.00%'), isNot(AppColors.candleUp));
    expect(_returnColor(tester, '0.00%'), isNot(AppColors.candleDown));
  });

  testWidgets('카드를 누르면 onTap 이 불린다', (tester) async {
    var tapped = 0;
    await _pump(tester, onTap: () => tapped++);

    // 숫자가 아니라 카드 아무 데나 눌러도 열려야 한다.
    await tester.tap(find.byType(TradeResultCard));
    await tester.pumpAndSettle();

    expect(tapped, 1);
  });

  testWidgets('onTap 이 없으면 누를 수 없다', (tester) async {
    await _pump(tester);

    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
  });
}
