import 'package:injectable/injectable.dart';

import '../../domain/chat/chat_model.dart';
import '../../domain/chat/chat_vendor.dart';
import 'anthropic_chat_model.dart';
import 'openai_chat_model.dart';

/// 벤더 → 어댑터. 어댑터는 구체 타입으로 등록돼 여기서만 모인다.
@LazySingleton(as: ChatModelRegistry)
class VendorChatModelRegistry implements ChatModelRegistry {
  VendorChatModelRegistry(this._anthropic, this._openai);

  final AnthropicChatModel _anthropic;
  final OpenAiChatModel _openai;

  @override
  ChatModel of(ChatVendor vendor) => switch (vendor) {
    ChatVendor.anthropic => _anthropic,
    ChatVendor.openai => _openai,
  };
}
