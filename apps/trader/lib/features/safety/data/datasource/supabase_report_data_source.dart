import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:core/core.dart';
import '../../domain/entity/report_reason.dart';
import '../../domain/entity/report_target.dart';
import '../mapper/report_target_mapper.dart';
import 'report_data_source.dart';

@LazySingleton(as: ReportDataSource)
class SupabaseReportDataSource implements ReportDataSource {
  SupabaseReportDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<void> submitReport(
    ReportTarget target, {
    required ReportReason reason,
    String? detail,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const Failure.auth(
        message: '로그인이 필요합니다',
        failureCode: FailureCode.authenticationRequired,
      );
    }

    final payload = ReportTargetMapper.toPayload(target);

    // reporter_id 와 status 는 보내지 않는다. GRANT 에 없어서 보내면 42501 로
    // 막히고, DB 의 default 가 채우므로 위조 경로가 없다.
    await _client.from('reports').insert({
      'target_type': payload.type,
      'target_id': payload.id,
      'reason': reason.code,
      'detail': detail,
    });
  }
}
