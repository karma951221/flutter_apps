import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_trade_result_dto.freezed.dart';
part 'post_trade_result_dto.g.dart';

/// 게시물 단건 조회가 `trade_sessions` 를 임베드해 받는 결과 요약의 전송 형식.
///
/// 키 이름은 피드 뷰의 `trade_result` jsonb 와 같게 맞췄다
/// (`SupabasePostDataSource._columns` 의 별칭). 그래서 feed 의
/// `FeedTradeResultDto` 와 모양이 같지만, DTO 는 feature 마다 따로 갖는다
/// (아키텍처 규칙 ⑥ — data 는 다른 feature 를 참조하지 않는다).
///
/// `start_day`/`end_day` 는 `date` 컬럼이라 `YYYY-MM-DD` 로 오고 `DateTime`
/// 필드가 표준 파서로 그대로 받는다.
@freezed
@JsonSerializable()
class PostTradeResultDto with _$PostTradeResultDto {
  const PostTradeResultDto({
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

  factory PostTradeResultDto.fromJson(Map<String, dynamic> json) =>
      _$PostTradeResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PostTradeResultDtoToJson(this);
}
