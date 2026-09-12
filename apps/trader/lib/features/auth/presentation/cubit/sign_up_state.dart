import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/validation/nickname_check.dart';
import 'submit_state.dart';

part 'sign_up_state.freezed.dart';

/// 회원가입 화면의 상태.
///
/// 제출과 닉네임 사전 확인은 서로를 기다리지 않는다. 하나의 union 으로 묶으면
/// 확인 결과가 제출 중 상태를 지우므로, 두 축을 따로 들고 있는다.
@freezed
class SignUpState with _$SignUpState {
  @override
  final SubmitState submit;
  @override
  final NicknameCheck nicknameCheck;

  const SignUpState({
    this.submit = const SubmitState.idle(),
    this.nicknameCheck = const NicknameCheck.idle(),
  });
}
