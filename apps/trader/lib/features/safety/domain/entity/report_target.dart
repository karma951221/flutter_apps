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

  /// 채팅 메시지. 방별 닉네임이어도 제재는 계정에 붙으므로 대상은 메시지이고,
  /// 트리거가 그 메시지의 sender_id 를 찾아 자기 신고를 막는다 (F9).
  const factory ReportTarget.chatMessage(String id) = ReportChatMessageTarget;
}
