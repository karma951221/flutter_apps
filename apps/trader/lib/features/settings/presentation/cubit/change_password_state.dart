import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';

part 'change_password_state.freezed.dart';

/// 비밀번호 변경 제출 상태.
///
/// auth 의 `SubmitState` 와 모양이 같지만 그쪽은 auth presentation 소유다.
/// feature 간 참조는 domain 까지만 한다는 규칙([아키텍처 ⑥])을 지키려고 여기서
/// 따로 든다. 새 입력 값은 상태에 두지 않는다 — TextEditingController 가 들고
/// 있으면 충분하고, 키 입력마다 리빌드할 이유가 없다.
@freezed
sealed class ChangePasswordState with _$ChangePasswordState {
  const factory ChangePasswordState.idle() = ChangePasswordIdle;
  const factory ChangePasswordState.inProgress() = ChangePasswordInProgress;
  const factory ChangePasswordState.success() = ChangePasswordSuccess;
  const factory ChangePasswordState.failure(Failure failure) =
      ChangePasswordFailure;
}
