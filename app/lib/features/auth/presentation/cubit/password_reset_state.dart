import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';

part 'password_reset_state.freezed.dart';

/// 비밀번호 재설정 진행 단계.
///
/// 링크(딥링크) 대신 6자리 코드를 쓰기 때문에 세 단계가 한 화면 안에서 흐른다.
enum PasswordResetStep {
  /// 이메일 입력 → 코드 발송
  requestCode,

  /// 코드 입력 → 검증
  verifyCode,

  /// 새 비밀번호 입력
  newPassword,

  /// 완료
  done,
}

@freezed
class PasswordResetState with _$PasswordResetState {
  @override
  final PasswordResetStep step;
  @override
  final bool isLoading;
  @override
  final String email;
  @override
  final Failure? failure;

  const PasswordResetState({
    this.step = PasswordResetStep.requestCode,
    this.isLoading = false,
    this.email = '',
    this.failure,
  });
}
