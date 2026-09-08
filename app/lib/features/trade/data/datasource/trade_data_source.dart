import '../../domain/entity/trade_side.dart';
import '../cursor/trade_cursor.dart';
import '../dto/trade_session_dto.dart';
import '../dto/trade_session_summary_dto.dart';

/// 모의투자 판 원격 데이터 원본. RPC 5개 + `trade_sessions` 테이블 조회.
abstract interface class TradeDataSource {
  /// `start_trade_session` RPC. 새 판의 id 를 돌려준다.
  Future<String> startSession();

  /// `get_trade_session` RPC. 게스트도 부를 수 있다 — 끝난 판의 결과를 열 수
  /// 있어야 하므로 로그인 여부를 확인하지 않는다.
  Future<TradeSessionDto> getSession(String sessionId);

  /// 내 진행 중인 판의 id. 없으면 null.
  Future<String?> getActiveSessionId();

  /// `place_trade_order` RPC.
  Future<TradeSessionDto> placeOrder({
    required String sessionId,
    required TradeSide side,
    required double quantity,
  });

  /// `advance_trade_session` RPC.
  Future<TradeSessionDto> advance(String sessionId);

  /// `finish_trade_session` RPC.
  Future<TradeSessionDto> finish(String sessionId);

  /// 내 지난 판(끝난 판만) 목록. 최신순.
  Future<List<TradeSessionSummaryDto>> getPastSessions({
    required int limit,
    TradeCursor? cursor,
  });
}
