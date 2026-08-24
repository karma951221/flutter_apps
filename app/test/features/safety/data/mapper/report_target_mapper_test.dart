import 'package:daylog/features/safety/data/mapper/report_target_mapper.dart';
import 'package:daylog/features/safety/domain/entity/report_target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportTargetMapper.toPayload', () {
    test('post 는 target_type=post 로 매핑된다', () {
      final payload = ReportTargetMapper.toPayload(
        const ReportTarget.post('post-1'),
      );
      expect(payload.type, 'post');
      expect(payload.id, 'post-1');
    });

    test('comment 는 target_type=comment 로 매핑된다', () {
      final payload = ReportTargetMapper.toPayload(
        const ReportTarget.comment('comment-1'),
      );
      expect(payload.type, 'comment');
      expect(payload.id, 'comment-1');
    });

    test('user 는 target_type=user 로 매핑된다', () {
      final payload = ReportTargetMapper.toPayload(
        const ReportTarget.user('user-1'),
      );
      expect(payload.type, 'user');
      expect(payload.id, 'user-1');
    });
  });
}
