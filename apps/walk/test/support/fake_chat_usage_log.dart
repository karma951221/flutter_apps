import 'dart:async';

import 'package:walk/domain/chat/chat_usage_log.dart';

/// 받은 기록을 모으는 가짜.
class FakeChatUsageLog implements ChatUsageLog {
  final records = <ChatUsageRecord>[];

  /// 있으면 record 가 이 오류를 던진다.
  Object? failWith;

  /// 있으면 record 가 이 future 가 끝날 때까지 끝나지 않는다.
  Future<void>? hangOn;

  @override
  Future<void> record(ChatUsageRecord record) {
    records.add(record);
    final error = failWith;
    if (error != null) throw error;
    return hangOn ?? Future<void>.value();
  }
}
