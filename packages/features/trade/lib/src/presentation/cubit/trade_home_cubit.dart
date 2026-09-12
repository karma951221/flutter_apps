import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:core/core.dart';
import '../../domain/usecase/trade_use_case.dart';
import 'trade_home_state.dart';

/// 모의투자 홈 — 진행 중인 판과 지난 판 목록을 소유한다.
@injectable
class TradeHomeCubit extends Cubit<TradeHomeState> {
  TradeHomeCubit(this._useCase) : super(const TradeHomeState.loading());

  static const _pageSize = 20;

  final TradeUseCase _useCase;

  /// 지금 화면이 기다리고 있는 조회의 세대 번호.
  ///
  /// [load] 가 값을 올리고, 요청을 띄우는 쪽은 보내기 전에 잡아 두었다가
  /// 응답 시점에 달라졌으면 버린다 — [FollowListCubit] 과 같은 장치다.
  int _generation = 0;

  /// 진행 중인 판과 지난 판 첫 페이지를 함께 읽는다.
  ///
  /// 두 조회는 서로를 기다릴 이유가 없어 같이 띄운다. 하나라도 실패하면
  /// 절반짜리 화면 대신 실패로 간다 — 지난 판만 보이는데 진행 중인 판이
  /// 있는지 없는지 모르는 상태는 사용자가 판단할 수 없기 때문이다.
  Future<void> load() async {
    final generation = ++_generation;
    emit(const TradeHomeState.loading());

    final (activeResult, pastResult) = await (
      _useCase.getActiveSession(),
      _useCase.getPastSessions(limit: _pageSize),
    ).wait;
    if (isClosed || generation != _generation) return;

    emit(switch ((activeResult, pastResult)) {
      (Err(:final failure), _) ||
      (_, Err(:final failure)) => TradeHomeState.failure(failure),
      (Ok(value: final active), Ok(value: final page)) => TradeHomeState.loaded(
        active: active,
        past: page.items,
        nextCursor: page.nextCursor,
      ),
    });
  }

  Future<void> refresh() => load();

  /// 지난 판 다음 페이지를 이어 붙인다.
  Future<void> loadMore() async {
    final current = state;
    if (current is! TradeHomeLoaded ||
        current.isLoadingMore ||
        !current.canLoadMore) {
      return;
    }

    final generation = _generation;
    emit(current.copyWith(isLoadingMore: true));
    final result = await _useCase.getPastSessions(
      limit: _pageSize,
      cursor: current.nextCursor,
    );
    // 이 요청이 날아가 있는 동안 load 가 목록을 갈아치웠다면, 이 페이지는
    // 사라진 목록의 뒷부분이다. 지금 목록에 이어 붙이면 그 사이 판이 빠지고
    // nextCursor 도 옛 경계로 되돌아간다 — 버려야 하는 응답이다.
    if (isClosed || generation != _generation) return;

    // 세대가 같아도 start 가 상태를 바꿨을 수 있으므로 요청 전 스냅샷이
    // 아니라 지금의 state 위에 붙인다.
    final latest = state;
    if (latest is! TradeHomeLoaded) return;

    emit(switch (result) {
      Ok(value: final page) => latest.copyWith(
        past: [...latest.past, ...page.items],
        nextCursor: page.nextCursor,
        isLoadingMore: false,
      ),
      Err() => latest.copyWith(isLoadingMore: false),
    });
  }

  /// 새 판을 시작하고 만들어진 판의 id 를 돌려준다.
  ///
  /// 화면은 돌려받은 id 로 판 화면에 들어가고, 실패는 스낵바로 보여준다.
  /// 시작 버튼은 loaded 에서만 눌리므로, 그 밖의 상태에서 들어온 호출은
  /// "지금은 시작할 수 없다"로 보고 [FailureCode.operationInProgress] 를
  /// 돌려준다.
  Future<Result<String>> start() async {
    final current = state;
    if (current is! TradeHomeLoaded || current.isStarting) {
      return const Err(
        Failure.validation(
          message: '이미 처리 중입니다',
          failureCode: FailureCode.operationInProgress,
        ),
      );
    }

    emit(current.copyWith(isStarting: true));
    final result = await _useCase.startSession();
    if (isClosed) return result;

    switch (result) {
      // 새 판이 곧 진행 중인 판이 된다. 돌아왔을 때 홈이 옛 화면이 아니도록
      // 여기서 다시 읽는다 — 잠금은 load 가 새 상태로 갈아치우며 풀린다.
      case Ok():
        await load();
      case Err():
        final latest = state;
        if (latest is TradeHomeLoaded) {
          emit(latest.copyWith(isStarting: false));
        }
    }
    return result;
  }
}
