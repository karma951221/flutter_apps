import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/presentation/settings/cubit/connection_status_cubit.dart';

import '../../../support/fake_chat_settings.dart';

void main() {
  test('키가 있으면 벤더, 없으면 null', () async {
    final chat = FakeChatSettings('sk-ant-123456')..vendor = ChatVendor.openai;
    final cubit = ConnectionStatusCubit(chat);
    expect(cubit.state.loaded, isFalse);

    await cubit.load();
    expect(
      cubit.state,
      const ConnectionStatus(ai: ChatVendor.openai, loaded: true),
    );

    chat.key = null;
    await cubit.load();
    expect(cubit.state, const ConnectionStatus(loaded: true));
    expect(chat.apiKeyCalls, 0);
  });

  test('보안 저장소 오류면 연결 안 됨', () async {
    final chat = FakeChatSettings('k')..failWith = Exception('storage');
    final cubit = ConnectionStatusCubit(chat);
    await cubit.load();
    expect(cubit.state, const ConnectionStatus(loaded: true));
  });
}
