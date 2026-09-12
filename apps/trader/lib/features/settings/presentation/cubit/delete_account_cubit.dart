import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/usecase/auth_use_case.dart';
import 'delete_account_state.dart';

/// 회원 탈퇴를 실행한다.
///
/// 확인은 화면이 받는다 — 이 cubit 이 불렸다는 것은 이미 확인을 거쳤다는
/// 뜻이다. 성공하면 auth 상태 스트림이 로그아웃으로 바뀌고 라우터가 로그인
/// 화면으로 보내므로, 여기서는 화면 전환을 하지 않는다.
@injectable
class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  DeleteAccountCubit(this._useCase) : super(const DeleteAccountState.idle());

  final AuthUseCase _useCase;

  Future<void> submit() async {
    if (state is DeleteAccountInProgress) return;
    emit(const DeleteAccountState.inProgress());

    final result = await _useCase.deleteAccount();
    if (isClosed) return;

    emit(
      result.when(
        // 성공 상태로 되돌리지 않는다 — 화면째로 사라질 것이다.
        ok: (_) => const DeleteAccountState.inProgress(),
        err: DeleteAccountState.failure,
      ),
    );
  }
}
