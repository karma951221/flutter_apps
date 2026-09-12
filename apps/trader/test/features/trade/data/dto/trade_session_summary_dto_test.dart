import 'package:daylog/features/trade/data/dto/trade_session_summary_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('끝난 판 목록 행을 파싱한다', () {
    final dto = TradeSessionSummaryDto.fromJson({
      'id': 'session-1',
      'created_at': '2026-08-30T09:00:00.000Z',
      'finished_at': '2026-08-30T10:00:00.000Z',
      'step': 60,
      'revealed_symbol': 'AAA',
      'revealed_start_day': '2026-01-01',
      'revealed_end_day': '2026-06-01',
      'final_equity': 10500,
      'return_pct': 5,
      'buy_hold_return_pct': 3.2,
      'max_drawdown_pct': 12.5,
      'trade_count': 4,
    });

    expect(dto.id, 'session-1');
    expect(dto.createdAt, DateTime.parse('2026-08-30T09:00:00.000Z'));
    expect(dto.finishedAt, DateTime.parse('2026-08-30T10:00:00.000Z'));
    expect(dto.step, 60);
    expect(dto.revealedSymbol, 'AAA');
    expect(dto.finalEquity, isA<double>());
    expect(dto.finalEquity, 10500.0);
    expect(dto.tradeCount, 4);
  });

  test('진행 중인 판이 섞여 들어와도 결과 컬럼은 전부 null 이다', () {
    final dto = TradeSessionSummaryDto.fromJson({
      'id': 'session-2',
      'created_at': '2026-08-30T09:00:00.000Z',
      'finished_at': null,
      'step': 3,
      'revealed_symbol': null,
      'revealed_start_day': null,
      'revealed_end_day': null,
      'final_equity': null,
      'return_pct': null,
      'buy_hold_return_pct': null,
      'max_drawdown_pct': null,
      'trade_count': null,
    });

    expect(dto.finishedAt, isNull);
    expect(dto.revealedSymbol, isNull);
    expect(dto.finalEquity, isNull);
  });

  test('JSON 왕복', () {
    final dto = TradeSessionSummaryDto(
      id: 'session-3',
      createdAt: DateTime.parse('2026-08-30T09:00:00.000Z'),
      finishedAt: DateTime.parse('2026-08-30T10:00:00.000Z'),
      step: 60,
      revealedSymbol: 'BBB',
      revealedStartDay: DateTime.parse('2026-02-01'),
      revealedEndDay: DateTime.parse('2026-07-01'),
      finalEquity: 9800.5,
      returnPct: -1.5,
      buyHoldReturnPct: -0.2,
      maxDrawdownPct: 8.1,
      tradeCount: 2,
    );

    expect(TradeSessionSummaryDto.fromJson(dto.toJson()), dto);
  });
}
