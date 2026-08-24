import 'package:freezed_annotation/freezed_annotation.dart';

part 'report_target.freezed.dart';

/// 신고할 대상.
///
/// DB 가 폴리모픽(`target_type` + `target_id`)이라 FK 가 없다. 대상이 실재하는지는
/// 트리거가 보고, 앱에서는 이 타입이 "무엇을 신고하는가" 의 단일 표현이다.
/// 대상이 늘면 여기 변형 하나와 data 의 매핑 한 줄만 는다.
@freezed
sealed class ReportTarget with _$ReportTarget {
  const factory ReportTarget.post(String id) = ReportPostTarget;
  const factory ReportTarget.comment(String id) = ReportCommentTarget;
  const factory ReportTarget.user(String id) = ReportUserTarget;
}
