import 'package:freezed_annotation/freezed_annotation.dart';

import 'trade_result.dart';

part 'trade_session_summary.freezed.dart';

/// 지난 판 목록의 한 행.
///
/// 목록은 끝난 판만 읽으므로 [result] 는 실제로는 항상 채워져 있다. 그래도
/// 타입은 nullable 로 둔다 — 진행 중인 판이 섞여 들어오는 경로가 생겨도
/// 화면이 죽지 않게 하기 위해서다.
@freezed
class TradeSessionSummary with _$TradeSessionSummary {
  @override
  final String id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? finishedAt;
  @override
  final TradeResult? result;

  const TradeSessionSummary({
    required this.id,
    required this.createdAt,
    this.finishedAt,
    this.result,
  });
}
