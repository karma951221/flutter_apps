import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_connection.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/presentation/settings/cubit/chat_settings_cubit.dart';

import '../../../support/fake_chat_settings.dart';

void main() {
  const key = 'sk-ant-api03-xyz1234SECRET';

  test('키가 있으면 마스킹 미리보기가 보인다', () async {
    final cubit = ChatSettingsCubit(FakeChatSettings(key));
    await cubit.load();

    expect(cubit.state.loading, isFalse);
    expect(cubit.state.connection?.keyPreview, 'sk-ant-api03-xyz1••••');
    expect(cubit.state.connection?.vendor, ChatVendor.anthropic);
    await cubit.close();
  });

  test('상태 toString 에 원문이 없다', () async {
    final cubit = ChatSettingsCubit(FakeChatSettings(key));
    await cubit.load();

    expect(cubit.state.toString(), isNot(contains('234SECRET')));
    expect(cubit.state.toString(), isNot(contains(key)));
    await cubit.close();
  });

  test('저장하면 연결이 생기고 끊으면 사라진다', () async {
    final settings = FakeChatSettings();
    final cubit = ChatSettingsCubit(settings);
    await cubit.load();
    expect(cubit.state.connection, isNull);

    await cubit.save(' sk-ant-api03-abcd5678 ');
    expect(cubit.state.connection?.keyPreview, 'sk-ant-api03-abcd••••');
    expect(cubit.state.connection?.status, ChatKeyStatus.unverified);
    expect(settings.key, 'sk-ant-api03-abcd5678');

    await cubit.delete();
    expect(cubit.state.connection, isNull);
    await cubit.close();
  });

  test('빈 키를 저장하면 끊는다', () async {
    final settings = FakeChatSettings(key);
    final cubit = ChatSettingsCubit(settings);
    await cubit.load();

    expect(await cubit.save('   '), isTrue);
    expect(cubit.state.connection, isNull);
    expect(settings.key, isNull);
    await cubit.close();
  });

  test('읽다 실패해도 loading 이 끝나고 미연결', () async {
    final cubit = ChatSettingsCubit(
      FakeChatSettings(key)..failWith = Exception('keystore'),
    );
    await cubit.load();

    expect(cubit.state.loading, isFalse);
    expect(cubit.state.connection, isNull);
    await cubit.close();
  });

  test('저장 · 삭제가 실패하면 false 를 돌려주고 loading 이 끝난다', () async {
    final settings = FakeChatSettings(key);
    final cubit = ChatSettingsCubit(settings);
    await cubit.load();
    settings.failWith = Exception('keystore');

    expect(await cubit.save('sk-ant-api03-new00000'), isFalse);
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.connection?.keyPreview, 'sk-ant-api03-xyz1••••');

    expect(await cubit.delete(), isFalse);
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.connection?.keyPreview, 'sk-ant-api03-xyz1••••');
    await cubit.close();
  });

  test('저장 · 삭제가 성공하면 true', () async {
    final cubit = ChatSettingsCubit(FakeChatSettings());
    await cubit.load();

    expect(await cubit.save('sk-ant-api03-abcd5678'), isTrue);
    expect(await cubit.delete(), isTrue);
    await cubit.close();
  });

  test('apiKey() 를 부르지 않는다', () async {
    final settings = FakeChatSettings();
    final cubit = ChatSettingsCubit(settings);
    await cubit.load();
    await cubit.save('sk-ant-api03-abcd5678');
    await cubit.delete();

    expect(settings.apiKeyCalls, 0);
    await cubit.close();
  });
}
