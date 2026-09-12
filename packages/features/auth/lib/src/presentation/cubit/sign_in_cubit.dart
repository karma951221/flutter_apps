import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecase/auth_use_case.dart';
import 'submit_state.dart';

@injectable
class SignInCubit extends Cubit<SubmitState> {
  SignInCubit(this._useCase) : super(const SubmitState.idle());

  final AuthUseCase _useCase;

  Future<void> submit({required String email, required String password}) async {
    if (state is SubmitInProgress) return;
    emit(const SubmitState.inProgress());

    final result = await _useCase.signIn(email: email, password: password);

    emit(
      result.when(
        ok: (_) => const SubmitState.success(),
        err: SubmitState.failure,
      ),
    );
  }
}
