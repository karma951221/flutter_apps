import 'package:daylog/features/trade/data/dto/trade_candle_dto.dart';
import 'package:daylog/features/trade/data/dto/trade_order_dto.dart';
import 'package:daylog/features/trade/data/dto/trade_result_dto.dart';
import 'package:daylog/features/trade/data/dto/trade_session_dto.dart';
import 'package:daylog/features/trade/data/dto/trade_session_summary_dto.dart';
import 'package:daylog/features/trade/data/mapper/trade_session_mapper.dart';
import 'package:daylog/features/trade/domain/entity/trade_side.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TradeCandleDtoMapper', () {
    test('필드를 그대로 옮긴다', () {
      const dto = TradeCandleDto(index: 10, open: 1, high: 2, low: 0.5, close: 1.5);

      final entity = dto.toEntity();

      expect(entity.index, 10);
      expect(entity.open, 1);
      expect(entity.high, 2);
      expect(entity.low, 0.5);
      expect(entity.close, 1.5);
    });
  });

  group('TradeOrderDtoMapper', () {
    test('side 문자열을 TradeSide 로 바꾼다', () {
      const buy = TradeOrderDto(step: 0, side: 'buy', quantity: 1, price: 100, fee: 0.1);
      const sell = TradeOrderDto(step: 1, side: 'sell', quantity: 1, price: 100, fee: 0.1);

      expect(buy.toEntity().side, TradeSide.buy);
      expect(sell.toEntity().side, TradeSide.sell);
    });
  });

  group('TradeResultDtoMapper', () {
    test('필드를 그대로 옮긴다', () {
      final dto = TradeResultDto(
        symbol: 'AAA',
        startDay: DateTime.parse('2026-01-01'),
        endDay: DateTime.parse('2026-06-01'),
        endIndex: 119,
        finalEquity: 10500,
        returnPct: 5,
        buyHoldReturnPct: 3.2,
        maxDrawdownPct: 12.5,
        tradeCount: 4,
      );

      final entity = dto.toEntity();

      expect(entity.symbol, 'AAA');
      expect(entity.startDay, dto.startDay);
      expect(entity.endDay, dto.endDay);
      expect(entity.endIndex, 119);
      expect(entity.finalEquity, 10500);
      expect(entity.tradeCount, 4);
    });
  });

  group('TradeSessionDtoMapper', () {
    test('진행 중인 판은 result 가 null 이다', () {
      const dto = TradeSessionDto(
        id: 's1',
        userId: 'u1',
        step: 3,
        cash: 9000,
        quantity: 1.5,
        isFinished: false,
        candles: [TradeCandleDto(index: 0, open: 100, high: 100, low: 100, close: 100)],
        orders: [TradeOrderDto(step: 0, side: 'buy', quantity: 1.5, price: 100, fee: 0.15)],
      );

      final entity = dto.toEntity();

      expect(entity.id, 's1');
      expect(entity.userId, 'u1');
      expect(entity.isFinished, isFalse);
      expect(entity.candles, hasLength(1));
      expect(entity.orders, hasLength(1));
      expect(entity.orders.single.side, TradeSide.buy);
      expect(entity.result, isNull);
    });

    test('끝난 판은 result 를 함께 옮긴다', () {
      final dto = TradeSessionDto(
        id: 's2',
        userId: 'u2',
        step: 60,
        cash: 10500,
        quantity: 0,
        isFinished: true,
        result: TradeResultDto(
          symbol: 'AAA',
          startDay: DateTime.parse('2026-01-01'),
          endDay: DateTime.parse('2026-06-01'),
          endIndex: 119,
          finalEquity: 10500,
          returnPct: 5,
          buyHoldReturnPct: 3.2,
          maxDrawdownPct: 12.5,
          tradeCount: 4,
        ),
      );

      final entity = dto.toEntity();

      expect(entity.result, isNotNull);
      expect(entity.result!.symbol, 'AAA');
      expect(entity.result!.endIndex, 119);
    });
  });

  group('TradeSessionSummaryDtoMapper', () {
    test('결과 컬럼이 모두 채워졌으면 TradeResult 를 만든다 — endIndex 는 min(59+step, 119)', () {
      final dto = TradeSessionSummaryDto(
        id: 's3',
        createdAt: DateTime.parse('2026-08-30T09:00:00.000Z'),
        finishedAt: DateTime.parse('2026-08-30T10:00:00.000Z'),
        step: 60,
        revealedSymbol: 'AAA',
        revealedStartDay: DateTime.parse('2026-01-01'),
        revealedEndDay: DateTime.parse('2026-06-01'),
        finalEquity: 10500,
        returnPct: 5,
        buyHoldReturnPct: 3.2,
        maxDrawdownPct: 12.5,
        tradeCount: 4,
      );

      final entity = dto.toEntity();

      expect(entity.id, 's3');
      expect(entity.finishedAt, dto.finishedAt);
      expect(entity.result, isNotNull);
      expect(entity.result!.symbol, 'AAA');
      expect(entity.result!.endIndex, 119);
    });

    test('도중에 끝난 판은 endIndex = 59 + step 이다', () {
      final dto = TradeSessionSummaryDto(
        id: 's4',
        createdAt: DateTime.parse('2026-08-30T09:00:00.000Z'),
        finishedAt: DateTime.parse('2026-08-30T09:30:00.000Z'),
        step: 20,
        revealedSymbol: 'BBB',
        revealedStartDay: DateTime.parse('2026-02-01'),
        revealedEndDay: DateTime.parse('2026-03-01'),
        finalEquity: 9800,
        returnPct: -2,
        buyHoldReturnPct: -1,
        maxDrawdownPct: 5,
        tradeCount: 1,
      );

      expect(dto.toEntity().result!.endIndex, 79);
    });

    test('결과 컬럼이 하나라도 비면 result 는 null 이다', () {
      final dto = TradeSessionSummaryDto(
        id: 's5',
        createdAt: DateTime.parse('2026-08-30T09:00:00.000Z'),
        step: 3,
      );

      expect(dto.toEntity().result, isNull);
    });
  });
}
