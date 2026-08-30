import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entity/report_reason.dart';

part 'report_state.freezed.dart';

/// 신고 시트의 상태.
@freezed
class ReportState with _$ReportState {
  const ReportState({
    this.reason,
    this.detail = '',
    this.isSubmitting = false,
    this.failure,
  });

  /// 선택된 사유. null 이면 아직 고르지 않았고 제출할 수 없다.
  @override
  final ReportReason? reason;

  /// 상세 설명 원문. 정규화는 저장 직전 domain 이 한다.
  @override
  final String detail;

  @override
  final bool isSubmitting;

  @override
  final Failure? failure;

  bool get canSubmit => reason != null && !isSubmitting;
}
