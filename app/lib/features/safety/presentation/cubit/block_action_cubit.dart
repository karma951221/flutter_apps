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
    emit(state.copyWith(isBlocking: false, failure: nextFailure));
    return succeeded;
  }
}
