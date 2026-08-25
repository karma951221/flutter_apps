import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/usecase/safety_use_case.dart';
import 'block_action_state.dart';

/// 사용자 차단 동작을 소유한다.
///
/// `feed_page` · `profile_page`가 각자 위젯 메서드 안에서 직접
/// `getIt<SafetyUseCase>().blockUser(...)`를 부르던 것을 이 cubit으로
/// 옮겼다 — 아키텍처 규칙 ③(presentation은 Bloc/Cubit을 거쳐 facade에
/// 닿는다)을 어기고 있었고, 그 탓에 두 화면에 같은 로직이 그대로 복제돼
/// 있었다. `ReportCubit`이 신고에서 하는 역할과 같다.
///
/// `BuildContext` 를 알지 못한다 — 목록에서 걷어내는 것(`FeedCubit.removeAuthor`
/// / `refresh()`)과 스낵바를 띄우는 것은 호출한 화면의 몫이다.
@injectable
class BlockActionCubit extends Cubit<BlockActionState> {
  BlockActionCubit(this._useCase) : super(const BlockActionState());

  final SafetyUseCase _useCase;

  /// 내가 이 사용자를 차단했는지만 읽는다. 상대가 나를 차단했는지는 이
  /// 화면에서 알 필요도, 드러낼 이유도 없다.
  Future<void> loadStatus(String userId) async {
    emit(state.copyWith(isLoadingStatus: true, failure: null));
    final result = await _useCase.isBlockedByMe(userId);
    if (isClosed) return;

    result.when(
      ok: (isBlocked) =>
          emit(state.copyWith(isLoadingStatus: false, isBlocked: isBlocked)),
      // 실패하면 상태를 알 수 없으므로 null로 되돌린다. 화면은 차단 관련
      // 항목을 숨겨, 틀린 동작을 권하는 것보다 안전하게 처리한다.
      err: (failure) => emit(
        state.copyWith(
          isLoadingStatus: false,
          isBlocked: null,
          failure: failure,
        ),
      ),
    );
  }

  /// 사용자를 차단한다. 성공하면 `true`, 실패하면 `false` 를 돌려준다.
  Future<bool> block(String userId) async {
    emit(state.copyWith(isBlocking: true, failure: null));
    final result = await _useCase.blockUser(userId);
    if (isClosed) return false;

    Failure? nextFailure;
    var succeeded = false;
    result.when(
      ok: (_) => succeeded = true,
      err: (failure) => nextFailure = failure,
    );
    emit(
      state.copyWith(
        isBlocking: false,
        isBlocked: succeeded ? true : state.isBlocked,
        failure: nextFailure,
      ),
    );
    return succeeded;
  }

  /// 사용자의 차단을 해제한다. 성공하면 `true`, 실패하면 `false` 를 돌려준다.
  Future<bool> unblock(String userId) async {
    emit(state.copyWith(isBlocking: true, failure: null));
    final result = await _useCase.unblockUser(userId);
    if (isClosed) return false;

    Failure? nextFailure;
    var succeeded = false;
    result.when(
      ok: (_) => succeeded = true,
      err: (failure) => nextFailure = failure,
    );
    emit(
      state.copyWith(
        isBlocking: false,
        isBlocked: succeeded ? false : state.isBlocked,
        failure: nextFailure,
      ),
    );
    return succeeded;
  }
}
