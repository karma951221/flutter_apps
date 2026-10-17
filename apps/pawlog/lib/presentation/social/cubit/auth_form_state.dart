import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_form_state.freezed.dart';

/// 로그인 · 가입 폼의 보내기 상태. 입력 검증은 폼(`Form`)이 한다.
@freezed
sealed class AuthFormState with _$AuthFormState {
  const factory AuthFormState.idle() = AuthFormIdle;
  const factory AuthFormState.submitting() = AuthFormSubmitting;
  const factory AuthFormState.succeeded() = AuthFormSucceeded;
  const factory AuthFormState.failed(Failure failure) = AuthFormFailed;
}
