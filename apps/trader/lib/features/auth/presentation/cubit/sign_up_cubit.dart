import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/validation/nickname_check.dart';
import '../../../../core/validation/validators.dart';
import '../../domain/usecase/auth_use_case.dart';
import 'sign_up_state.dart';
import 'submit_state.dart';

@injectable
class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit(this._useCase) : super(const SignUpState());

  final AuthUseCase _useCase;

  Timer? _nicknameDebounce;

  /// 늦게 도착한 옛 응답이 새 결과를 덮어쓰지 않게 하는 표식.
  int _nicknameRequest = 0;

  Future<void> submit({
    required String email,
    required String password,
    required String nickname,
  }) async {
    if (state.submit is SubmitInProgress) return;
    emit(state.copyWith(submit: const SubmitState.inProgress()));

    final result = await _useCase.signUp(
      email: email,
      password: password,
      nickname: nickname,
    );
    // 가입 도중 화면을 떠났을 수 있다. 닫힌 뒤의 emit 은 예외가 된다.
    if (isClosed) return;

    emit(
      result.when(
        // 가입이 끝나면 사전 확인은 할 말이 없다. 이 화면은 곧 사라진다.
        ok: (_) => const SignUpState(submit: SubmitState.success()),
        err: (failure) => state.copyWith(submit: SubmitState.failure(failure)),
      ),
    );
  }

  /// 닉네임 입력이 바뀔 때마다 부른다.
  ///
  /// 형식이 어긋난 값은 조회하지 않는다 — 폼 검증이 이미 말해주므로 서버까지
  /// 갈 이유가 없다. 프로필 편집과 달리 "지금 쓰고 있는 닉네임" 은 없다.
  void checkNickname(String nickname) {
    _nicknameDebounce?.cancel();
    _nicknameRequest++;

    final trimmed = nickname.trim();
    if (Validators.nickname(trimmed) != null) {
      emit(state.copyWith(nicknameCheck: const NicknameCheck.idle()));
      return;
    }

    emit(state.copyWith(nicknameCheck: const NicknameCheck.checking()));
    _nicknameDebounce = Timer(
      nicknameCheckDebounce,
      () => _runNicknameCheck(trimmed, _nicknameRequest),
    );
  }

  Future<void> _runNicknameCheck(String nickname, int request) async {
    final result = await _useCase.isNicknameAvailable(nickname);
    if (isClosed || request != _nicknameRequest) return;

    emit(
      state.copyWith(
        nicknameCheck: result.when(
          ok: (available) => available
              ? const NicknameCheck.available()
              : const NicknameCheck.taken(),
          // 확인에 실패하면 조용히 접는다. 가입할 때 DB 가 최종 판정을 한다.
          err: (_) => const NicknameCheck.idle(),
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _nicknameDebounce?.cancel();
    return super.close();
  }
}
