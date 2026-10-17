import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/social/usecase/social_use_case.dart';
import 'auth_form_state.dart';

@injectable
class AuthCubit extends Cubit<AuthFormState> {
  AuthCubit(this._useCase) : super(const AuthFormState.idle());

  final SocialUseCase _useCase;

  Future<void> signIn({required String email, required String password}) =>
      _submit(() => _useCase.signIn(email, password));

  Future<void> signUp({
    required String email,
    required String password,
    required String nickname,
  }) => _submit(() => _useCase.signUp(email, password, nickname));

  /// 입력을 고치면 지난 실패(닉네임 칸 오류)를 지운다.
  void clearFailure() {
    if (state is AuthFormFailed) emit(const AuthFormState.idle());
  }

  Future<void> _submit(Future<Result<void>> Function() action) async {
    // 두 번 눌러도 요청은 한 번.
    if (state is AuthFormSubmitting || state is AuthFormSucceeded) return;
    emit(const AuthFormState.submitting());
    final result = await action();
    if (isClosed) return;
    emit(switch (result) {
      Ok() => const AuthFormState.succeeded(),
      Err(:final failure) => AuthFormState.failed(failure),
    });
  }
}
