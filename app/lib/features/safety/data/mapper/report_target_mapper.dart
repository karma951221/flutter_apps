import '../../domain/entity/report_target.dart';

/// 대상 → DB 의 (target_type, target_id) 매핑이 있는 유일한 곳.
///
/// 대상이 늘면 여기 한 줄과 ReportTarget 의 변형, 그리고 CHECK 제약만 는다.
/// domain 과 presentation 은 그대로다.
abstract final class ReportTargetMapper {
  static ({String type, String id}) toPayload(ReportTarget target) =>
      switch (target) {
        ReportPostTarget(:final id) => (type: 'post', id: id),
        ReportCommentTarget(:final id) => (type: 'comment', id: id),
        ReportUserTarget(:final id) => (type: 'user', id: id),
      };
}
