import 'dart:math' as math;

import 'package:daylog/design_system/theme/app_colors.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/trade/domain/entity/trade_candle.dart';
import 'package:daylog/features/trade/domain/entity/trade_order.dart';
import 'package:daylog/features/trade/domain/entity/trade_side.dart';
import 'package:daylog/features/trade/domain/trade_rules.dart';
import 'package:daylog/features/trade/presentation/widget/trade_candle_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const size = Size(360, 240);
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.seed);

  TradeCandle candleAt(int index, {double base = 100}) => TradeCandle(
    index: index,
    open: base,
    high: base + 4,
    low: base - 4,
    close: base + 2,
  );

  TradeCandleChartPainter painterOf({
    required List<TradeCandle> candles,
    List<TradeOrder> orders = const [],
    int? endIndex,
  }) => TradeCandleChartPainter(
    candles: candles,
    orders: orders,
    warmupCount: TradeRules.warmupCandles,
    totalCandles: TradeRules.totalCandles,
    endIndex: endIndex,
    upColor: AppColors.candleUp,
    downColor: AppColors.candleDown,
    warmupColor: scheme.surfaceContainerHighest,
    gridColor: scheme.outlineVariant,
    axisColor: scheme.outline,
    labelStyle: const TextStyle(fontSize: 11),
  );

  group('markers', () {
    test('주문마다 하나씩, 매수는 저가 아래 매도는 고가 위에 찍는다', () {
      final candles = [
        for (var i = 0; i <= 62; i++) candleAt(i, base: 100 + i.toDouble()),
      ];
      final painter = painterOf(
        candles: candles,
        orders: const [
          TradeOrder(
            step: 0,
            side: TradeSide.buy,
            quantity: 10,
            price: 100,
            fee: 1,
          ),
          TradeOrder(
            step: 1,
            side: TradeSide.sell,
            quantity: 4,
            price: 101,
            fee: 0.4,
          ),
          TradeOrder(
            step: 3,
            side: TradeSide.buy,
            quantity: 2,
            price: 103,
            fee: 0.2,
          ),
        ],
      );

      final markers = painter.markers(size);

      expect(markers, hasLength(3));
      expect(markers.map((m) => m.index), [59, 60, 62]);
      expect(markers.map((m) => m.side), [
        TradeSide.buy,
        TradeSide.sell,
        TradeSide.buy,
      ]);

      for (final marker in markers) {
        final candle = candles[marker.index];
        expect(marker.position.dx, painter.xForIndex(marker.index, size));
        switch (marker.side) {
          case TradeSide.buy:
            // 화면 좌표는 아래로 갈수록 커진다 = 저가보다 아래.
            expect(
              marker.position.dy,
              greaterThan(painter.yForPrice(candle.low, size)),
            );
          case TradeSide.sell:
            expect(
              marker.position.dy,
              lessThan(painter.yForPrice(candle.high, size)),
            );
        }
      }
    });

    test('주문이 없으면 마커도 없다', () {
      expect(painterOf(candles: [candleAt(59)]).markers(size), isEmpty);
    });
  });

  group('x 축', () {
    test('워밍업 경계는 plot 폭의 60/120 지점이다', () {
      final painter = painterOf(
        candles: [for (var i = 0; i < 60; i++) candleAt(i)],
      );
      final plot = painter.plotRect(size);

      expect(
        painter.warmupBoundaryX(size),
        closeTo(plot.left + plot.width * 60 / 120, 0.001),
      );
    });

    test('봉이 60개뿐이어도 슬롯은 120 기준이라 index 59 가 전체 폭의 절반 근처다', () {
      final painter = painterOf(
        candles: [for (var i = 0; i < 60; i++) candleAt(i)],
      );
      final plot = painter.plotRect(size);

      expect(painter.slotWidth(size), closeTo(plot.width / 120, 0.001));
      expect(
        painter.xForIndex(59, size),
        closeTo(size.width / 2, size.width * 0.1),
      );
      expect(
        painter.xForIndex(59, size),
        lessThan(painter.warmupBoundaryX(size)),
      );
      // 마지막 슬롯은 봉이 없어도 자리를 지킨다.
      expect(
        painter.xForIndex(119, size),
        closeTo(plot.right, plot.width / 120),
      );
    });

    test('x 라벨은 날짜가 아니라 D0 기준 상대 표기다', () {
      final painter = painterOf(candles: [candleAt(59)]);

      expect(painter.labelForIndex(0), 'D−59');
      expect(painter.labelForIndex(59), 'D0');
      expect(painter.labelForIndex(119), 'D+60');
    });
  });

  group('yTicks', () {
    test('보이는 봉 범위를 3~4개 눈금으로 덮는다', () {
      for (final spread in [1.0, 7.0, 23.0, 140.0]) {
        final painter = painterOf(
          candles: [
            candleAt(59, base: 100),
            candleAt(60, base: 100 + spread),
          ],
        );
        final ticks = painter.yTicks();

        expect(
          ticks.length,
          allOf(greaterThanOrEqualTo(3), lessThanOrEqualTo(4)),
          reason: 'spread $spread 에서 ${ticks.length} 개',
        );
        final lows = [96.0, 96.0 + spread];
        final highs = [104.0, 104.0 + spread];
        for (final tick in ticks) {
          expect(tick, greaterThanOrEqualTo(lows.reduce(math.min) - 1e-9));
          expect(tick, lessThanOrEqualTo(highs.reduce(math.max) + 1e-9));
        }
      }
    });

    test('평평한 구간에서도 눈금이 잡힌다', () {
      final painter = painterOf(
        candles: const [
          TradeCandle(index: 59, open: 100, high: 100, low: 100, close: 100),
        ],
      );

      expect(
        painter.yTicks().length,
        allOf(greaterThanOrEqualTo(3), lessThanOrEqualTo(4)),
      );
    });

    test('보이는 봉이 없으면 빈 목록이다', () {
      expect(painterOf(candles: const []).yTicks(), isEmpty);
    });
  });

  group('shouldRepaint', () {
    test('입력이 같으면 다시 그리지 않는다', () {
      final candles = [candleAt(59)];

      expect(
        painterOf(candles: candles).shouldRepaint(painterOf(candles: candles)),
        isFalse,
      );
      expect(
        painterOf(
          candles: candles,
          endIndex: 119,
        ).shouldRepaint(painterOf(candles: candles)),
        isTrue,
      );
      expect(
        painterOf(
          candles: [...candles, candleAt(60)],
        ).shouldRepaint(painterOf(candles: candles)),
        isTrue,
      );
    });
  });

  group('위젯', () {
    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    );

    testWidgets('봉이 비어 있어도 예외 없이 그린다', (tester) async {
      await pump(tester, const TradeCandleChart(candles: []));

      expect(find.byType(TradeCandleChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('봉과 주문이 있으면 예외 없이 그린다', (tester) async {
      await pump(
        tester,
        TradeCandleChart(
          candles: [
            for (var i = 0; i < 80; i++)
              candleAt(i, base: 100 + (i % 7).toDouble()),
          ],
          orders: const [
            TradeOrder(
              step: 2,
              side: TradeSide.buy,
              quantity: 10,
              price: 100,
              fee: 1,
            ),
            TradeOrder(
              step: 9,
              side: TradeSide.sell,
              quantity: 10,
              price: 104,
              fee: 1,
            ),
          ],
          endIndex: 79,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
