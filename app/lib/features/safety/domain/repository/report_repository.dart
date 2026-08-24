import '../../../../core/result/result.dart';
import '../entity/report_reason.dart';
import '../entity/report_target.dart';

/// 신고 저장소.
///
/// 조회는 여기 없다. RLS 가 본인 신고 조회를 열어 두지만 화면이 쓰지 않는다 —
/// 쓰지 않는 경로를 만들면 유지할 것만 는다.
abstract interface class ReportRepository {
  /// 신고를 접수한다. 중복·자기 신고·삭제된 대상은 서버가 거부한다.
  Future<Result<void>> submitReport(
    ReportTarget target, {
    required ReportReason reason,
    String? detail,
  });
}
