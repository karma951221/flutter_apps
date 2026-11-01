import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_vendor.dart';

/// 테스트가 준 어댑터를 돌려주는 [ChatModelRegistry]. 없는 벤더면 UnsupportedError.
class FakeChatModelRegistry implements ChatModelRegistry {
  FakeChatModelRegistry(this.models);

  final Map<ChatVendor, ChatModel> models;

  /// [of] 로 받은 벤더들(부른 순서대로).
  final calls = <ChatVendor>[];

  @override
  ChatModel of(ChatVendor vendor) {
    calls.add(vendor);
    return models[vendor] ?? (throw UnsupportedError('$vendor'));
  }
}
