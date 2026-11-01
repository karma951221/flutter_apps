import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_history_settings.dart';
import 'package:walk/presentation/settings/cubit/chat_history_settings_cubit.dart';

import '../../../support/fake_chat_history.dart';

void main() {
  late FakeChatHistorySettings settings;
  late FakeChatHistoryCount history;
  late ChatHistorySettingsCubit cubit;

  setUp(() {
    settings = FakeChatHistorySettings(ChatRetention.day90);
    history = FakeChatHistoryCount(3);
    cubit = ChatHistorySettingsCubit(settings, history);
  });
  tearDown(() => cubit.close());

  test('load 는 보관 기간과 대화 수', () async {
    await cubit.load();

    expect(cubit.state.retention, ChatRetention.day90);
    expect(cubit.state.conversationCount, 3);
  });

  test('setRetention 은 저장하고 상태를 바꾼다', () async {
    await cubit.load();
    await cubit.setRetention(ChatRetention.day30);

    expect(settings.retention, ChatRetention.day30);
    expect(cubit.state.retention, ChatRetention.day30);
  });

  test('deleteAllConversations 뒤 수는 0', () async {
    await cubit.load();

    expect(await cubit.deleteAllConversations(), 3);
    expect(cubit.state.conversationCount, 0);
  });

  test('deleteAllConversations 가 실패하면 던지고 수는 그대로', () async {
    await cubit.load();
    history.failDeleteAll = true;

    await expectLater(cubit.deleteAllConversations(), throwsStateError);
    expect(cubit.state.conversationCount, 3);
  });

  test('모두 지운 뒤 대화 수를 못 읽으면 0 으로 두고 던지지 않는다', () async {
    await cubit.load();
    history.failCount = true;

    expect(await cubit.deleteAllConversations(), 3);
    expect(cubit.state.conversationCount, 0);
  });
}
