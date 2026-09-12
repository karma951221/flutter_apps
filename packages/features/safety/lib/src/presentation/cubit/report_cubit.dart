import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:core/core.dart';
import '../../domain/entity/report_reason.dart';
import '../../domain/entity/report_target.dart';
import '../../domain/usecase/safety_use_case.dart';
import 'report_state.dart';

/// 신고 시트의 입력·제출을 소유한다.
///
/// `BuildContext` 를 알지 못한다 — 시트를 닫는 것과 스낵바를 띄우는 것은
/// 호출한 화면의 몫이다.
@injectable
class ReportCubit extends Cubit<ReportState> {
  ReportCubit(this._useCase) : super(const ReportState());

  final SafetyUseCase _useCase;

  void selectReason(ReportReason reason) {
    emit(state.copyWith(reason: reason, failure: null));
  }

  void changeDetail(String value) {
    emit(state.copyWith(detail: value));
  }

  /// 신고를 제출한다. 접수되면 `true`, 실패하면 `false` 를 돌려준다.
  Future<bool> submit(ReportTarget target) async {
    final reason = state.reason;
    if (reason == null) return false;

    emit(state.copyWith(isSubmitting: true, failure: null));
    final result = await _useCase.submit(
      target,
      reason: reason,
      detail: state.detail,
    );
    if (isClosed) return false;

    Failure? nextFailure;
    var succeeded = false;
    result.when(
      ok: (_) => succeeded = true,
      err: (failure) => nextFailure = failure,
    );
    emit(state.copyWith(isSubmitting: false, failure: nextFailure));
    return succeeded;
  }
}
