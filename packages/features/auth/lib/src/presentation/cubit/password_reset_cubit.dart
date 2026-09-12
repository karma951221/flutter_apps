import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecase/auth_use_case.dart';
import 'password_reset_state.dart';

/// 비밀번호 재설정 3단계를 순서대로 진행한다.
///
///   1) sendCode    이메일로 6자리 코드 발송
///   2) verifyCode  코드 검증 → 임시 세션 획득
///   3) updatePassword 새 비밀번호로 교체 → 로그아웃 → 로그인 화면
@injectable
class PasswordResetCubit extends Cubit<PasswordResetState> {
  PasswordResetCubit(this._useCase) : super(const PasswordResetState());

  final AuthUseCase _useCase;

  Future<void> sendCode(String email) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, failure: null, email: email.trim()));

    final result = await _useCase.sendPasswordResetCode(email);

    emit(
      result.when(
        ok: (_) => state.copyWith(
          isLoading: false,
          step: PasswordResetStep.verifyCode,
        ),
        err: (f) => state.copyWith(isLoading: false, failure: f),
      ),
    );
  }

  Future<void> verifyCode(String code) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _useCase.verifyPasswordResetCode(
      email: state.email,
      code: code,
    );

    emit(
      result.when(
        ok: (_) => state.copyWith(
          isLoading: false,
          step: PasswordResetStep.newPassword,
        ),
        err: (f) => state.copyWith(isLoading: false, failure: f),
      ),
    );
  }

  Future<void> updatePassword(String newPassword) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _useCase.updatePassword(newPassword);

    emit(
      result.when(
        ok: (_) =>
            state.copyWith(isLoading: false, step: PasswordResetStep.done),
        err: (f) => state.copyWith(isLoading: false, failure: f),
      ),
    );
  }

  /// 코드를 못 받았을 때 이메일 입력으로 되돌아간다.
  void backToEmail() =>
      emit(state.copyWith(step: PasswordResetStep.requestCode, failure: null));
}
