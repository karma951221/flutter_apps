import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:feature_auth/feature_auth.dart';
import 'change_password_state.dart';

/// 로그인한 사용자가 자기 비밀번호를 바꾼다.
///
/// 재설정(코드 발송 → 검증 → 교체)과 달리 이미 세션이 있으므로 마지막 단계 하나만
/// 필요하다. 그래서 auth 의 `AuthUseCase.updatePassword` 를 그대로 쓰고 settings
/// 쪽에 새 domain 코드를 만들지 않는다.
@injectable
class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  ChangePasswordCubit(this._useCase) : super(const ChangePasswordState.idle());

  final AuthUseCase _useCase;

  Future<void> submit(String newPassword) async {
    if (state is ChangePasswordInProgress) return;
    emit(const ChangePasswordState.inProgress());

    final result = await _useCase.updatePassword(newPassword);

    emit(
      result.when(
        ok: (_) => const ChangePasswordState.success(),
        err: ChangePasswordState.failure,
      ),
    );
  }
}
