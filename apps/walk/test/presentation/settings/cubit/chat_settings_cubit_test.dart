import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_settings.dart';
import 'package:walk/presentation/settings/cubit/chat_settings_cubit.dart';

class FakeChatSettings implements ChatSettings {
  FakeChatSettings([this.key]);

  String? key;

  @override
  Future<String?> apiKey() async => key;

  @override
  Future<void> saveApiKey(String value) async {
    final t = value.trim();
    key = t.isEmpty ? null : t;
  }

  @override
  Future<void> deleteApiKey() async => key = null;

  @override
  bool consented = false;

  @override
  Future<void> setConsented() async => consented = true;
}

void main() {
  test('키가 있으면 마지막 4자만 힌트로 보인다', () async {
    final cubit = ChatSettingsCubit(FakeChatSettings('sk-ant-xyz1234'));
    await cubit.load();

    expect(cubit.state.loading, isFalse);
    expect(cubit.state.keyHint, '…1234');
    await cubit.close();
  });

  test('상태 toString 에 전체 키가 없다', () async {
    final cubit = ChatSettingsCubit(FakeChatSettings('sk-ant-xyz1234'));
    await cubit.load();

    expect(cubit.state.toString(), isNot(contains('sk-ant')));
    await cubit.close();
  });

  test('저장하면 힌트가 생기고 삭제하면 사라진다', () async {
    final cubit = ChatSettingsCubit(FakeChatSettings());
    await cubit.load();
    expect(cubit.state.keyHint, isNull);

    await cubit.save(' sk-ant-abcd ');
    expect(cubit.state.keyHint, '…abcd');

    await cubit.delete();
    expect(cubit.state.keyHint, isNull);
    await cubit.close();
  });
}
