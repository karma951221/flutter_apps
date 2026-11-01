import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_connection.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/presentation/settings/cubit/chat_settings_cubit.dart';

import '../../../support/fake_chat_key_verifier.dart';
import '../../../support/fake_chat_settings.dart';

void main() {
  const key = 'sk-ant-api03-xyz1234SECRET';
  late FakeChatKeyVerifier verifier;

  setUp(() => verifier = FakeChatKeyVerifier());

  ChatSettingsCubit cubitOf(FakeChatSettings settings) =>
      ChatSettingsCubit(settings, verifier);

  test('키가 있으면 마스킹 미리보기가 보인다', () async {
    final cubit = cubitOf(FakeChatSettings(key));
    await cubit.load();

    expect(cubit.state.loading, isFalse);
    expect(cubit.state.connection?.keyPreview, 'sk-ant-api03-xyz1••••');
    expect(cubit.state.connection?.vendor, ChatVendor.anthropic);
    await cubit.close();
  });

  test('읽다 실패해도 loading 이 끝나고 미연결', () async {
    final cubit = cubitOf(
      FakeChatSettings(key)..failWith = Exception('keystore'),
    );
    await cubit.load();

    expect(cubit.state.loading, isFalse);
    expect(cubit.state.connection, isNull);
    await cubit.close();
  });

  group('check', () {
    test('check 는 trim 한 키로 verify 하고 결과를 ChatKeyCheck 로 바꾼다', () async {
      final cubit = cubitOf(FakeChatSettings());

      verifier.result = const ModelListResult.ok([]);
      expect(await cubit.check('  sk-ant-api03-abcd5678 '), ChatKeyCheck.valid);
      verifier.result = const ModelListResult.invalidKey();
      expect(await cubit.check('sk-ant-api03-abcd5678'), ChatKeyCheck.invalid);
      verifier.result = const ModelListResult.unreachable();
      expect(
        await cubit.check('sk-ant-api03-abcd5678'),
        ChatKeyCheck.unreachable,
      );

      expect(verifier.calls.first, (
        ChatVendor.anthropic,
        'sk-ant-api03-abcd5678',
      ));
      await cubit.close();
    });

    test('check 는 저장소를 건드리지 않는다', () async {
      final settings = FakeChatSettings();
      final cubit = cubitOf(settings);
      await cubit.load();

      await cubit.check('sk-ant-api03-abcd5678');

      expect(settings.key, isNull);
      expect(cubit.state.connection, isNull);
      await cubit.close();
    });
  });

  group('connect', () {
    test(
      'connect(valid) 는 valid 로, connect(unreachable) 는 unverified 로 저장하고 다시 읽는다',
      () async {
        final settings = FakeChatSettings();
        final cubit = cubitOf(settings);
        await cubit.load();

        expect(
          await cubit.connect(' sk-ant-api03-abcd5678 ', ChatKeyCheck.valid),
          isTrue,
        );
        expect(settings.key, 'sk-ant-api03-abcd5678');
        expect(cubit.state.connection?.status, ChatKeyStatus.valid);
        expect(cubit.state.connection?.keyPreview, 'sk-ant-api03-abcd••••');

        expect(
          await cubit.connect(
            'sk-ant-api03-efgh9999',
            ChatKeyCheck.unreachable,
          ),
          isTrue,
        );
        expect(cubit.state.connection?.status, ChatKeyStatus.unverified);
        expect(cubit.state.connection?.keyPreview, 'sk-ant-api03-efgh••••');
        await cubit.close();
      },
    );

    test('connect(invalid) 는 ArgumentError', () async {
      final settings = FakeChatSettings();
      final cubit = cubitOf(settings);

      expect(
        () => cubit.connect('sk-ant-api03-abcd5678', ChatKeyCheck.invalid),
        throwsArgumentError,
      );
      expect(settings.key, isNull);
      await cubit.close();
    });

    test('쓰기 실패면 false 이고 기존 연결 그대로', () async {
      final settings = FakeChatSettings(key);
      final cubit = cubitOf(settings);
      await cubit.load();
      settings.failWith = Exception('keystore');

      expect(
        await cubit.connect('sk-ant-api03-new00000', ChatKeyCheck.valid),
        isFalse,
      );
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.connection?.keyPreview, 'sk-ant-api03-xyz1••••');
      await cubit.close();
    });
  });

  group('disconnect', () {
    test('disconnect 성공이면 true 이고 미연결', () async {
      final settings = FakeChatSettings(key);
      final cubit = cubitOf(settings);
      await cubit.load();

      expect(await cubit.disconnect(), isTrue);
      expect(cubit.state.connection, isNull);
      expect(settings.key, isNull);
      await cubit.close();
    });

    test('disconnect 실패면 false 이고 연결 그대로', () async {
      final settings = FakeChatSettings(key);
      final cubit = cubitOf(settings);
      await cubit.load();
      settings.failWith = Exception('keystore');

      expect(await cubit.disconnect(), isFalse);
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.connection?.keyPreview, 'sk-ant-api03-xyz1••••');
      await cubit.close();
    });
  });

  test('apiKey() 를 부르지 않는다', () async {
    final settings = FakeChatSettings();
    final cubit = cubitOf(settings);
    await cubit.load();
    final check = await cubit.check('sk-ant-api03-abcd5678');
    await cubit.connect('sk-ant-api03-abcd5678', check);
    await cubit.disconnect();

    expect(settings.apiKeyCalls, 0);
    await cubit.close();
  });

  test('상태 toString 에 원문이 없다', () async {
    final cubit = cubitOf(FakeChatSettings(key));
    await cubit.load();

    // 본문 5번째(`2`) 이후 글자는 없다.
    expect(cubit.state.toString(), isNot(contains('234')));
    expect(cubit.state.toString(), isNot(contains(key)));

    const typed = 'sk-ant-api03-wxyz9876TYPED';
    await cubit.connect(typed, await cubit.check(typed));
    expect(cubit.state.toString(), isNot(contains('9876')));
    expect(cubit.state.toString(), isNot(contains(typed)));
    await cubit.close();
  });
}
