import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecase/safety_use_case.dart';
import 'blocked_users_state.dart';

/// 차단 목록 화면의 조회·해제를 소유한다.
///
/// `BuildContext` 를 알지 못한다 — 스낵바를 띄우는 것은 화면의 몫이다.
@injectable
class BlockedUsersCubit extends Cubit<BlockedUsersState> {
  BlockedUsersCubit(this._useCase) : super(const BlockedUsersState());

  final SafetyUseCase _useCase;

  Future<void> load() async {
    emit(const BlockedUsersState());

    final result = await _useCase.getBlockedUsers();
    if (isClosed) return;

    emit(
      result.when(
        ok: (items) => BlockedUsersState(
          status: BlockedUsersStatus.loaded,
          items: items,
        ),
        err: (failure) => BlockedUsersState(
          status: BlockedUsersStatus.failure,
          failure: failure,
        ),
      ),
    );
  }

  /// 차단을 해제한다. 성공하면 목록에서 그 행을 걷어낸다.
  Future<bool> unblock(String userId) async {
    final result = await _useCase.unblockUser(userId);
    if (isClosed) return false;

    var succeeded = false;
    result.when(
      ok: (_) {
        succeeded = true;
        emit(
          state.copyWith(
            items: state.items.where((item) => item.id != userId).toList(),
          ),
        );
      },
      err: (_) {},
    );
    return succeeded;
  }
}
