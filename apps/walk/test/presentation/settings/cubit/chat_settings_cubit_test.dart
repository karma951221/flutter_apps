import 'package:flutter_test/flutter_test.dart';
import 'package:walk/presentation/settings/cubit/chat_settings_cubit.dart';

import '../../../support/fake_chat_settings.dart';

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

  test('키를 읽다 실패해도 loading 이 끝나고 힌트는 없다', () async {
    final cubit = ChatSettingsCubit(
      FakeChatSettings('sk-ant-xyz1234')..failWith = Exception('keystore'),
    );
    await cubit.load();

    expect(cubit.state.loading, isFalse);
    expect(cubit.state.keyHint, isNull);
    await cubit.close();
  });

  test('저장 · 삭제가 실패하면 false 를 돌려주고 loading 이 끝난다', () async {
    final settings = FakeChatSettings('sk-ant-xyz1234');
    final cubit = ChatSettingsCubit(settings);
    await cubit.load();
    settings.failWith = Exception('keystore');

    expect(await cubit.save('sk-ant-new0000'), isFalse);
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.keyHint, '…1234');

    expect(await cubit.delete(), isFalse);
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.keyHint, '…1234');
    await cubit.close();
  });

  test('저장 · 삭제가 성공하면 true', () async {
    final cubit = ChatSettingsCubit(FakeChatSettings());
    await cubit.load();

    expect(await cubit.save('sk-ant-abcd'), isTrue);
    expect(await cubit.delete(), isTrue);
    await cubit.close();
  });
}
