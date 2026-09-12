import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:core/core.dart';
import '../../domain/entity/trade_session.dart';
import '../../domain/entity/trade_side.dart';
import '../../domain/usecase/trade_use_case.dart';
import 'trade_session_state.dart';

/// 판 하나를 소유한다 — 진행 화면과 결과 화면이 같이 쓴다.
///
/// 결과 화면도 [load] 로 읽는다. `get_trade_session` 은 끝난 판이면 익명도
/// 읽을 수 있어서, 공유된 판을 열어보는 경로가 같은 조회를 탄다.
///
/// 주문·진행·종료는 모두 판 전체를 다시 돌려준다. 그래서 응답이 오면 로컬
/// 계산으로 손보지 않고 **서버가 준 판으로 통째로 덮어쓴다** — 잔고·수량·step
/// 의 정본은 서버 한 곳뿐이다.
@injectable
class TradeSessionCubit extends Cubit<TradeSessionState> {
  TradeSessionCubit(this._useCase) : super(const TradeSessionState.loading());

  final TradeUseCase _useCase;

  /// 지금 화면이 기다리고 있는 조회의 세대 번호. 늦게 도착한 옛 조회가
  /// 새 판을 덮어쓰지 못하게 막는다.
  int _generation = 0;

  Future<void> load(String sessionId) async {
    final generation = ++_generation;
    emit(const TradeSessionState.loading());

    final result = await _useCase.getSession(sessionId);
    if (isClosed || generation != _generation) return;

    emit(switch (result) {
      Ok(value: final session) => TradeSessionState.loaded(session: session),
      Err(:final failure) => TradeSessionState.failure(failure),
    });
  }

  Future<Result<TradeSession>> placeOrder({
    required TradeSide side,
    required double quantity,
  }) => _submit(
    (sessionId) => _useCase.placeOrder(
      sessionId: sessionId,
      side: side,
      quantity: quantity,
    ),
  );

  /// 다음 봉으로 넘어간다.
  ///
  /// step 59 에서 부르면 서버가 마지막 봉을 공개하고 판을 자동으로 끝낸다.
  /// 그때도 여기서는 그냥 끝난 판을 loaded 로 둔다 — 결과 화면으로 보낼지는
  /// `isFinished` 를 보고 화면이 정한다.
  Future<Result<TradeSession>> advance() => _submit(_useCase.advance);

  Future<Result<TradeSession>> finish() => _submit(_useCase.finish);

  /// 판을 바꾸는 호출 하나를 [TradeSessionLoaded.isSubmitting] 으로 잠그고 돈다.
  ///
  /// 실패는 상태에 남기지 않고 [Result] 로 돌려준다 — 화면이 스낵바로
  /// 보여주고, 판은 방금 전 모습 그대로 남아야 하기 때문이다.
  Future<Result<TradeSession>> _submit(
    Future<Result<TradeSession>> Function(String sessionId) action,
  ) async {
    final current = state;
    if (current is! TradeSessionLoaded || current.isSubmitting) {
      return const Err(
        Failure.validation(
          message: '이미 처리 중입니다',
          failureCode: FailureCode.operationInProgress,
        ),
      );
    }

    final generation = _generation;
    emit(current.copyWith(isSubmitting: true));
    final result = await action(current.session.id);
    // 응답이 날아오는 동안 load 가 판을 다시 읽기 시작했다면 이 응답은 옛
    // 판이다. Result 는 부른 쪽에 돌려주되 상태는 건드리지 않는다.
    if (isClosed || generation != _generation) return result;

    switch (result) {
      case Ok(value: final session):
        emit(TradeSessionState.loaded(session: session));
      case Err():
        final latest = state;
        if (latest is TradeSessionLoaded) {
          emit(latest.copyWith(isSubmitting: false));
        }
    }
    return result;
  }
}
