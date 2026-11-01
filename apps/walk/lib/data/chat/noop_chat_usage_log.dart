import 'package:injectable/injectable.dart';

import '../../domain/chat/chat_usage_log.dart';

/// 아무것도 하지 않는다. 기록 기획이 `DriftChatUsageLog` 로 바꿔 끼운다.
@LazySingleton(as: ChatUsageLog)
class NoopChatUsageLog implements ChatUsageLog {
  @override
  Future<void> record(ChatUsageRecord record) async {}
}
