import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_trade_result_dto.freezed.dart';
part 'feed_trade_result_dto.g.dart';

/// `posts_with_author.trade_result` jsonb 한 덩어리의 전송 형식.
///
/// 뷰가 내려주는 키는 여덟이고(apps/trader/docs/schema.md §6), post feature 의
/// `PostTradeResultDto` 와 모양이 같다. 그래도 따로 두는 이유는 같은 게시물을
/// 두 벌로 표현해서가 아니라 **data 계층은 feature 를 넘지 않기** 때문이다
/// (아키텍처 규칙 ⑥). 원천도 다르다 — 이쪽은 뷰의 집계 컬럼, 저쪽은 단건
/// 조회의 임베드다.
///
/// 날짜 둘은 `YYYY-MM-DD` 문자열로 오므로 `DateTime` 이 표준 파서로 받는다.
@freezed
@JsonSerializable()
class FeedTradeResultDto with _$FeedTradeResultDto {
  const FeedTradeResultDto({
    required this.sessionId,
    required this.symbol,
    required this.startDay,
    required this.endDay,
    required this.returnPct,
    required this.buyHoldReturnPct,
    required this.maxDrawdownPct,
    required this.tradeCount,
  });

  @override
  @JsonKey(name: 'session_id')
  final String sessionId;
  @override
  final String symbol;
  @override
  @JsonKey(name: 'start_day')
  final DateTime startDay;
  @override
  @JsonKey(name: 'end_day')
  final DateTime endDay;
  @override
  @JsonKey(name: 'return_pct')
  final double returnPct;
  @override
  @JsonKey(name: 'buy_hold_return_pct')
  final double buyHoldReturnPct;
  @override
  @JsonKey(name: 'max_drawdown_pct')
  final double maxDrawdownPct;
  @override
  @JsonKey(name: 'trade_count')
  final int tradeCount;

  factory FeedTradeResultDto.fromJson(Map<String, dynamic> json) =>
      _$FeedTradeResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FeedTradeResultDtoToJson(this);
}
