import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';

part 'submit_state.freezed.dart';

/// 폼 제출 상태.
///
/// 로그인·회원가입이 같은 모양이라 하나로 공유한다.
/// 입력값 자체는 상태에 두지 않는다 — TextEditingController 가 들고 있으면 충분하고,
/// 키 입력마다 상태를 갱신하면 얻는 것 없이 리빌드만 늘어난다.
@freezed
sealed class SubmitState with _$SubmitState {
  const factory SubmitState.idle() = SubmitIdle;
  const factory SubmitState.inProgress() = SubmitInProgress;
  const factory SubmitState.success() = SubmitSuccess;
  const factory SubmitState.failure(Failure failure) = SubmitFailure;
}
