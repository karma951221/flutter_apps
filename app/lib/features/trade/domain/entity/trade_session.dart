import 'package:freezed_annotation/freezed_annotation.dart';

import '../trade_rules.dart';
import 'trade_candle.dart';
import 'trade_order.dart';
import 'trade_result.dart';

part 'trade_session.freezed.dart';

/// 진행 중이거나 끝난 판 하나. RPC 가 매 호출마다 이 모양 그대로 돌려준다.
@freezed
class TradeSession with _$TradeSession {
  @override
  final String id;
  @override
  final String userId;
  @override
  final int step;
  @override
  final double cash;
  @override
  final double quantity;
  @override
  final bool isFinished;
  @override
  final List<TradeCandle> candles;
  @override
  final List<TradeOrder> orders;
  @override
  final TradeResult? result;

  const TradeSession({
    required this.id,
    required this.userId,
    required this.step,
    required this.cash,
    required this.quantity,
    required this.isFinished,
    required this.candles,
    required this.orders,
    this.result,
  });

  /// 지금 화면에 보이는 마지막(현재) 봉의 index.
  ///
  /// 끝난 판은 결과의 종료 index 를 쓴다 — step 60 자동 종료든 도중 [finish]
  /// 청산이든, 실제로 청산가를 매긴 봉은 그 index 다.
  int get currentIndex => isFinished
      ? (result?.endIndex ?? TradeRules.indexForStep(step))
      : TradeRules.indexForStep(step);

  /// 현재 봉의 정규화 종가.
  ///
  /// candles 는 RPC 계약상 항상 [TradeRules.warmupCandles] 개 이상 내려오고
  /// [currentIndex] 는 그 범위 안에 있다고 가정한다 — 비어 있는 경우를
  /// 방어적으로 처리하지 않는다. 계약이 깨지면 여기서 범위 예외로 드러나야
  /// 조용히 잘못된 값을 보여주는 것보다 낫다.
  double get currentClose => candles[currentIndex].close;

  /// 다음 step 으로 진행하거나 주문을 넣을 수 있는지.
  bool get canAdvance => !isFinished;
}
