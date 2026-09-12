import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';

part 'delete_account_state.freezed.dart';

/// 회원 탈퇴 제출 상태.
///
/// success 변형이 없다. 탈퇴가 성공하면 세션이 사라지고 라우터가 로그인
/// 화면으로 보내므로, 이 화면이 성공을 표시할 틈이 없다.
@freezed
sealed class DeleteAccountState with _$DeleteAccountState {
  const factory DeleteAccountState.idle() = DeleteAccountIdle;
  const factory DeleteAccountState.inProgress() = DeleteAccountInProgress;
  const factory DeleteAccountState.failure(Failure failure) =
      DeleteAccountFailure;
}
