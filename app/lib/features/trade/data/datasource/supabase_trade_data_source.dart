import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_code.dart';
import '../../domain/entity/trade_side.dart';
import '../cursor/trade_cursor.dart';
import '../dto/trade_session_dto.dart';
import '../dto/trade_session_summary_dto.dart';
import 'trade_data_source.dart';

@LazySingleton(as: TradeDataSource)
class SupabaseTradeDataSource implements TradeDataSource {
  SupabaseTradeDataSource(this._client);

  final SupabaseClient _client;

  static const _summaryColumns =
      'id, created_at, finished_at, step, revealed_symbol, '
      'revealed_start_day, revealed_end_day, final_equity, return_pct, '
      'buy_hold_return_pct, max_drawdown_pct, trade_count';

  @override
  Future<String> startSession() async {
    _requireSignedIn();
    final id = await _client.rpc('start_trade_session');
    return id as String;
  }

  @override
  Future<TradeSessionDto> getSession(String sessionId) async {
    // 로그인 검사를 걸지 않는다 — 게스트가 게시물에 붙은 끝난 판 결과를 연다.
    // 남의 진행 중 판·없는 id 는 RPC 가 같은 문구로 거절한다.
    final json = await _client.rpc(
      'get_trade_session',
      params: {'session_id': sessionId},
    );
    return TradeSessionDto.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<String?> getActiveSessionId() async {
    _requireSignedIn();
    // user_id 필터가 없어도 안전하다 — trade_sessions_select_own 정책이
    // finished_at is null 인 행은 내 것만 보여준다.
    final row = await _client
        .from('trade_sessions')
        .select('id')
        .isFilter('finished_at', null)
        .maybeSingle();
    return row?['id'] as String?;
  }

  @override
  Future<TradeSessionDto> placeOrder({
    required String sessionId,
    required TradeSide side,
    required double quantity,
  }) async {
    _requireSignedIn();
    final json = await _client.rpc(
      'place_trade_order',
      params: {'session_id': sessionId, 'side': side.wire, 'quantity': quantity},
    );
    return TradeSessionDto.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<TradeSessionDto> advance(String sessionId) async {
    _requireSignedIn();
    final json = await _client.rpc(
      'advance_trade_session',
      params: {'session_id': sessionId},
    );
    return TradeSessionDto.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<TradeSessionDto> finish(String sessionId) async {
    _requireSignedIn();
    final json = await _client.rpc(
      'finish_trade_session',
      params: {'session_id': sessionId},
    );
    return TradeSessionDto.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<TradeSessionSummaryDto>> getPastSessions({
    required int limit,
    TradeCursor? cursor,
  }) async {
    _requireSignedIn();

    // RLS 는 남의 끝난 판도 보여준다(trade_sessions_select_finished) — 내
    // 목록이어야 하므로 user_id 필터를 직접 건다.
    var query = _client
        .from('trade_sessions')
        .select(_summaryColumns)
        .eq('user_id', _client.auth.currentUser!.id)
        .not('finished_at', 'is', null);

    if (cursor != null) {
      final createdAt = cursor.createdAt.toUtc().toIso8601String();
      // (created_at, id) 사전식 비교. follow · feed 목록과 같은 커서 방식이다.
      query = query.or(
        'created_at.lt.$createdAt,'
        'and(created_at.eq.$createdAt,id.lt.${cursor.id})',
      );
    }

    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);

    return rows.map(TradeSessionSummaryDto.fromJson).toList();
  }

  void _requireSignedIn() {
    if (_client.auth.currentUser == null) {
      throw const Failure.auth(
        message: '로그인이 필요합니다',
        failureCode: FailureCode.authenticationRequired,
      );
    }
  }
}
