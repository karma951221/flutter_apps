import 'package:feature_safety/feature_safety.dart';
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

    test('chatMessage 는 target_type=chat_message 로 매핑된다', () {
      // 대상이 넷째로 늘었는데 테이블은 그대로다 — 폴리모픽 설계가 값을 한
      // 자리다 (F9).
      final payload = ReportTargetMapper.toPayload(
        const ReportTarget.chatMessage('msg-1'),
      );
      expect(payload.type, 'chat_message');
      expect(payload.id, 'msg-1');
    });
  });
}
