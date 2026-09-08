import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/trade/domain/entity/trade_candle.dart';
import 'package:daylog/features/trade/domain/entity/trade_session.dart';
import 'package:daylog/features/trade/domain/entity/trade_side.dart';
import 'package:daylog/features/trade/domain/ledger/trade_sizing.dart';
import 'package:daylog/features/trade/domain/trade_rules.dart';
import 'package:daylog/features/trade/presentation/widget/trade_order_sheet.dart';
import 'package:daylog/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TradeSession _session({double cash = 10000, double quantity = 0}) =>
    TradeSession(
      id: 's1',
      userId: 'me',
      step: 3,
      cash: cash,
      quantity: quantity,
      isFinished: false,
      candles: [
        for (var i = 0; i <= TradeRules.indexForStep(3); i++)
          TradeCandle(index: i, open: 100, high: 101, low: 99, close: 100),
      ],
      orders: const [],
    );

void main() {
  /// 시트를 띄우고, 시트가 돌려준 수량을 읽는 함수를 넘긴다.
  Future<double? Function()> pumpSheet(
    WidgetTester tester, {
    required TradeSide side,
    required TradeSession session,
  }) async {
    double? picked;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        // ko 가 ARB template 언어라 원문이 곧 기대값이다.
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async {
                  picked = await TradeOrderSheet.show(
                    context,
                    side: side,
                    session: session,
                  );
                },
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    return () => picked;
  }

  testWidgets('매수 시트는 프리셋 셋과 금액·수량 전환을 준다', (tester) async {
    await pumpSheet(tester, side: TradeSide.buy, session: _session());

    expect(find.text('매수'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('금액'), findsOneWidget);
    expect(find.text('수량'), findsOneWidget);
    expect(find.text('예상 수량'), findsOneWidget);
    expect(find.text('주문 후 현금'), findsOneWidget);
  });

  testWidgets('25% 프리셋은 현금의 4분의 1로 살 수 있는 수량을 미리 보여준다', (tester) async {
    final picked = await pumpSheet(
      tester,
      side: TradeSide.buy,
      session: _session(),
    );

    await tester.tap(find.text('25%'));
    await tester.pumpAndSettle();

    final quantity = TradeSizing.buyQuantity(
      cash: 10000,
      price: 100,
      feeRate: TradeRules.feeRate,
      fraction: 0.25,
    );
    // 2500 / (100 × 1.001) 을 소수 6자리로 내린 값.
    expect(quantity, 24.975024);
    expect(find.text('24.975024'), findsOneWidget);
    // 수수료 24.975024 × 100 × 0.001
    expect(find.text('2.50'), findsOneWidget);

    await tester.tap(find.text('주문하기'));
    await tester.pumpAndSettle();

    expect(picked(), quantity);
  });

  testWidgets('금액에서 수량으로 바꾸면 같은 숫자가 수량으로 읽힌다', (tester) async {
    await pumpSheet(tester, side: TradeSide.buy, session: _session());

    await tester.enterText(find.byType(TextField), '10');
    await tester.pumpAndSettle();

    // 금액 10 으로는 10 / 100.1 만큼 살 수 있다.
    expect(find.text('0.0999'), findsOneWidget);

    await tester.tap(find.text('수량'));
    await tester.pumpAndSettle();

    // 뜻이 달라지므로 입력란은 비워진다.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '주문하기'))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField), '10');
    await tester.pumpAndSettle();

    // 입력란과 예상 수량이 같은 숫자를 가리킨다.
    expect(find.text('10'), findsNWidgets(2));
    // 10 × 100 × 0.001
    expect(find.text('1.00'), findsOneWidget);
    // 10000 − (1000 + 1)
    expect(find.text('8,999.00'), findsOneWidget);
  });

  testWidgets('잔고를 넘는 매수는 확인을 막고 이유를 적는다', (tester) async {
    await pumpSheet(tester, side: TradeSide.buy, session: _session());

    await tester.enterText(find.byType(TextField), '99999');
    await tester.pumpAndSettle();

    expect(find.text('잔고가 부족합니다'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '주문하기'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('매도 시트는 수량만 받는다', (tester) async {
    final picked = await pumpSheet(
      tester,
      side: TradeSide.sell,
      session: _session(cash: 5000, quantity: 2.5),
    );

    expect(find.text('매도'), findsOneWidget);
    // 매도에는 금액 입력이 없다.
    expect(find.text('금액'), findsNothing);
    expect(find.text('예상 수령액'), findsOneWidget);
    expect(find.text('주문 후 보유 수량'), findsOneWidget);

    await tester.tap(find.text('100%'));
    await tester.pumpAndSettle();

    // 전량 매도는 내림 없이 보유량 그대로다.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      '2.5',
    );
    // 2.5 × 100 − 수수료 0.25
    expect(find.text('249.75'), findsOneWidget);
    expect(find.text('0.25'), findsOneWidget);

    await tester.tap(find.text('주문하기'));
    await tester.pumpAndSettle();

    expect(picked(), 2.5);
  });

  testWidgets('일부만 팔면 남는 수량을 미리 보여준다', (tester) async {
    await pumpSheet(
      tester,
      side: TradeSide.sell,
      session: _session(quantity: 2.5),
    );

    await tester.enterText(find.byType(TextField), '1');
    await tester.pumpAndSettle();

    // 1 × 100 − 수수료 0.1
    expect(find.text('99.90'), findsOneWidget);
    expect(find.text('0.10'), findsOneWidget);
    expect(find.text('1.5'), findsOneWidget);
  });

  testWidgets('보유량을 넘는 매도는 확인을 막고 이유를 적는다', (tester) async {
    await pumpSheet(
      tester,
      side: TradeSide.sell,
      session: _session(quantity: 2.5),
    );

    await tester.enterText(find.byType(TextField), '3');
    await tester.pumpAndSettle();

    expect(find.text('보유 수량이 부족합니다'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '주문하기'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('아무것도 입력하지 않으면 확인할 수 없다', (tester) async {
    await pumpSheet(tester, side: TradeSide.buy, session: _session());

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '주문하기'))
          .onPressed,
      isNull,
    );
  });
}
