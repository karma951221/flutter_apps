import 'package:injectable/injectable.dart';

import 'package:core/core.dart';
import '../../domain/entity/trade_session.dart';
import '../../domain/entity/trade_session_summary.dart';
import '../../domain/entity/trade_side.dart';
import '../../domain/repository/trade_repository.dart';
import '../cursor/trade_cursor.dart';
import '../datasource/trade_data_source.dart';
import '../dto/trade_session_summary_dto.dart';
import '../mapper/trade_session_mapper.dart';

/// TradeDataSource 를 domain Repository 계약으로 변환하는 구현체.
@LazySingleton(as: TradeRepository)
class TradeRepositoryImpl
    with RepositoryErrorHandler
    implements TradeRepository {
  TradeRepositoryImpl(this._dataSource);

  final TradeDataSource _dataSource;

  @override
  Future<Result<String>> startSession() =>
      guard(() => _dataSource.startSession());

  @override
  Future<Result<TradeSession>> getSession(String sessionId) =>
      guard(() async => (await _dataSource.getSession(sessionId)).toEntity());

  @override
  Future<Result<TradeSession?>> getActiveSession() => guard(() async {
    final activeId = await _dataSource.getActiveSessionId();
    if (activeId == null) return null;
    return (await _dataSource.getSession(activeId)).toEntity();
  });

  @override
  Future<Result<TradeSession>> placeOrder({
    required String sessionId,
    required TradeSide side,
    required double quantity,
  }) => guard(
    () async => (await _dataSource.placeOrder(
      sessionId: sessionId,
      side: side,
      quantity: quantity,
    )).toEntity(),
  );

  @override
  Future<Result<TradeSession>> advance(String sessionId) =>
      guard(() async => (await _dataSource.advance(sessionId)).toEntity());

  @override
  Future<Result<TradeSession>> finish(String sessionId) =>
      guard(() async => (await _dataSource.finish(sessionId)).toEntity());

  @override
  Future<Result<CursorPage<TradeSessionSummary>>> getPastSessions({
    required int limit,
    String? cursor,
  }) => guard(
    () async => _toPage(
      await _dataSource.getPastSessions(
        limit: limit + 1,
        cursor: TradeCursor.decode(cursor),
      ),
      limit,
    ),
  );

  /// 한 개를 더 받아 다음 페이지 존재 여부를 판정한다
  /// (`FollowRepositoryImpl._toPage` 와 같은 방식).
  CursorPage<TradeSessionSummary> _toPage(
    List<TradeSessionSummaryDto> rows,
    int limit,
  ) {
    final hasMore = rows.length > limit;
    final page = hasMore ? rows.take(limit).toList() : rows;

    return CursorPage<TradeSessionSummary>(
      items: page.map((dto) => dto.toEntity()).toList(),
      nextCursor: hasMore
          ? TradeCursor(
              createdAt: page.last.createdAt,
              id: page.last.id,
            ).encode()
          : null,
    );
  }
}
