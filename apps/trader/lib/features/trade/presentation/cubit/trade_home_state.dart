import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entity/trade_session.dart';
import '../../domain/entity/trade_session_summary.dart';

part 'trade_home_state.freezed.dart';

/// 모의투자 홈의 상태.
///
/// 진행 중인 판([TradeHomeLoaded.active])과 지난 판 목록은 한 화면이 함께
/// 보여주고 한 번의 조회에서 같이 오므로 상태도 하나로 묶는다 — 한쪽만
/// 채워진 절반 상태를 만들지 않고, 둘 중 하나라도 실패하면 [TradeHomeFailure] 다.
@freezed
sealed class TradeHomeState with _$TradeHomeState {
  const TradeHomeState._();

  const factory TradeHomeState.loading() = TradeHomeLoading;

  /// [active] 가 null 이면 진행 중인 판이 없다 — 화면은 "시작" 을 보여준다.
  const factory TradeHomeState.loaded({
    TradeSession? active,
    @Default(<TradeSessionSummary>[]) List<TradeSessionSummary> past,
    String? nextCursor,
    @Default(false) bool isLoadingMore,
    @Default(false) bool isStarting,
  }) = TradeHomeLoaded;

  const factory TradeHomeState.failure(Failure failure) = TradeHomeFailure;

  /// 지난 판을 더 읽을 수 있는지. 커서가 남아 있을 때만 참이다.
  bool get canLoadMore => switch (this) {
    TradeHomeLoaded(:final nextCursor) => nextCursor != null,
    _ => false,
  };
}
