import 'package:freezed_annotation/freezed_annotation.dart';

part 'trade_session_summary_dto.freezed.dart';
part 'trade_session_summary_dto.g.dart';

/// `trade_sessions` 테이블 목록 조회(지난 판) 한 행의 전송 형식.
///
/// RPC 의 `trade_session_state()` 와 달리 컬럼을 그대로 읽는다. `end_index` 는
/// 테이블에 없는 값이라 여기 없다 — 대신 `step` 을 읽어 mapper 가
/// `min(59 + step, 119)` 로 계산한다. 목록은 끝난 판만 조회하지만(§17), 결과
/// 컬럼 여덟은 스키마상 전부 nullable(끝나기 전엔 null)이라 DTO 도 그대로
/// nullable 로 둔다.
@freezed
@JsonSerializable()
class TradeSessionSummaryDto with _$TradeSessionSummaryDto {
  const TradeSessionSummaryDto({
    required this.id,
    required this.createdAt,
    this.finishedAt,
    required this.step,
    this.revealedSymbol,
    this.revealedStartDay,
    this.revealedEndDay,
    this.finalEquity,
    this.returnPct,
    this.buyHoldReturnPct,
    this.maxDrawdownPct,
    this.tradeCount,
  });

  @override
  final String id;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'finished_at')
  final DateTime? finishedAt;
  @override
  final int step;
  @override
  @JsonKey(name: 'revealed_symbol')
  final String? revealedSymbol;
  @override
  @JsonKey(name: 'revealed_start_day')
  final DateTime? revealedStartDay;
  @override
  @JsonKey(name: 'revealed_end_day')
  final DateTime? revealedEndDay;
  @override
  @JsonKey(name: 'final_equity')
  final double? finalEquity;
  @override
  @JsonKey(name: 'return_pct')
  final double? returnPct;
  @override
  @JsonKey(name: 'buy_hold_return_pct')
  final double? buyHoldReturnPct;
  @override
  @JsonKey(name: 'max_drawdown_pct')
  final double? maxDrawdownPct;
  @override
  @JsonKey(name: 'trade_count')
  final int? tradeCount;

  factory TradeSessionSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$TradeSessionSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TradeSessionSummaryDtoToJson(this);
}
