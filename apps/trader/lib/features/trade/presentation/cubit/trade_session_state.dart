import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';
import '../../domain/entity/trade_session.dart';

part 'trade_session_state.freezed.dart';

/// 판 하나(진행 중이든 끝났든)의 상태.
///
/// RPC 는 매매·진행·종료 어느 호출이든 판 전체를 다시 돌려주므로, 화면이
/// 들고 있어야 할 것은 [TradeSessionLoaded.session] 하나뿐이다. 로컬에서
/// 잔고나 step 을 따로 계산해 두지 않는다 — 계산의 정본은 서버다.
@freezed
sealed class TradeSessionState with _$TradeSessionState {
  const factory TradeSessionState.loading() = TradeSessionLoading;

  /// [isSubmitting] 은 주문·진행·종료가 날아가 있는 동안 참이다. 이 사이에
  /// 들어온 두 번째 요청은 cubit 이 거절한다.
  const factory TradeSessionState.loaded({
    required TradeSession session,
    @Default(false) bool isSubmitting,
  }) = TradeSessionLoaded;

  const factory TradeSessionState.failure(Failure failure) =
      TradeSessionFailure;
}
