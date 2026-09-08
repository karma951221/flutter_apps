import '../../../../core/pagination/cursor_page.dart';
import '../../../../core/result/result.dart';
import '../entity/trade_session.dart';
import '../entity/trade_session_summary.dart';
import '../entity/trade_side.dart';

/// 모의투자 판 저장소.
///
/// 사용자당 진행 중인 판은 1개다 — 서버가 그 불변식을 지킨다
/// ([FailureCode.tradeSessionAlreadyActive]).
abstract interface class TradeRepository {
  /// 새 판을 시작하고 그 id 를 돌려준다.
  Future<Result<String>> startSession();

  /// [sessionId] 판을 조회한다. 남의 판·없는 id 모두 존재 여부를 밝히지
  /// 않고 같은 실패([FailureCode.tradeSessionNotFound])로 온다.
  Future<Result<TradeSession>> getSession(String sessionId);

  /// 진행 중인 판을 가져온다. 없으면 null — 실패가 아니다.
  Future<Result<TradeSession?>> getActiveSession();

  /// 현재 step 에서 주문을 낸다. 잔고 부족·보유 초과는 서버가 거부한다.
  Future<Result<TradeSession>> placeOrder({
    required String sessionId,
    required TradeSide side,
    required double quantity,
  });

  /// 다음 step 으로 진행한다. step 59 에서 부르면 index 119 를 공개한 뒤
  /// 보유분을 청산하고 판을 자동 종료한다.
  Future<Result<TradeSession>> advance(String sessionId);

  /// 아무 step 에서나 현재 종가로 보유분을 청산하고 판을 끝낸다.
  Future<Result<TradeSession>> finish(String sessionId);

  /// 내 지난 판(끝난 판만) 목록을 최신순으로 돌려준다.
  Future<Result<CursorPage<TradeSessionSummary>>> getPastSessions({
    required int limit,
    String? cursor,
  });
}
