import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_connection.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/usecase/chat_model_choice.dart';
import 'package:walk/presentation/settings/cubit/chat_settings_cubit.dart';

import '../../../support/fake_chat_key_verifier.dart';
import '../../../support/fake_chat_model_catalog.dart';
import '../../../support/fake_chat_settings.dart';

void main() {
  const key = 'sk-ant-api03-xyz1234SECRET';
  const sonnet = ModelInfo(
    id: 'claude-sonnet-9-5',
    displayName: 'Claude Sonnet 9.5',
  );
  late FakeChatKeyVerifier verifier;
  late FakeChatModelCatalog catalog;

  setUp(() {
    verifier = FakeChatKeyVerifier();
    catalog = FakeChatModelCatalog();
  });

  ChatSettingsCubit cubitOf(FakeChatSettings settings) => ChatSettingsCubit(
    settings,
    verifier,
    ChatModelChoice(settings, catalog, verifier, const Clock()),
  );

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
  group('모델', () {
    test('load 가 refresh 를 부른다', () async {
      final settings = FakeChatSettings(key);
      verifier.stored = (
        ChatVendor.anthropic,
        const ModelListResult.ok([sonnet]),
      );
      final cubit = cubitOf(settings);

      await cubit.load();

      expect(verifier.fetchStoredCalls, 1);
      expect(cubit.state.model?.label, 'Claude Sonnet 9.5');
      expect(cubit.state.modelsUnavailable, isFalse);
      await cubit.close();
    });

    test('연결됐는데 목록을 받지 못하면 modelsUnavailable, retryModels 가 받으면 내린다', () async {
      final settings = FakeChatSettings(key);
      verifier.stored = (
        ChatVendor.anthropic,
        const ModelListResult.unreachable(),
      );
      final cubit = cubitOf(settings);
      await cubit.load();
      expect(cubit.state.modelsUnavailable, isTrue);
      expect(cubit.state.model, isNull);

      verifier.stored = (
        ChatVendor.anthropic,
        const ModelListResult.ok([sonnet]),
      );
      await cubit.retryModels();

      expect(cubit.state.modelsUnavailable, isFalse);
      expect(cubit.state.model?.label, 'Claude Sonnet 9.5');
      await cubit.close();
    });

    test('미연결이면 모델 없음이지만 modelsUnavailable 은 아니다', () async {
      final cubit = cubitOf(FakeChatSettings());
      await cubit.load();

      expect(cubit.state.model, isNull);
      expect(cubit.state.modelsUnavailable, isFalse);
      expect(verifier.fetchStoredCalls, 0);
      await cubit.close();
    });

    test('ok 확인 뒤 connect 하면 그 목록을 adopt(listModels 한 번)', () async {
      final settings = FakeChatSettings();
      final cubit = cubitOf(settings);
      await cubit.load();
      verifier.result = const ModelListResult.ok([sonnet]);

      final check = await cubit.check('sk-ant-api03-abcd5678');
      await cubit.connect('sk-ant-api03-abcd5678', check);
      await pumpEventQueue();

      expect(catalog.replaceCalls, [(ChatVendor.anthropic, 1)]);
      expect(verifier.calls, hasLength(1));
      expect(verifier.fetchStoredCalls, 0);
      expect(cubit.state.model?.label, 'Claude Sonnet 9.5');
      await cubit.close();
    });

    test('unreachable 로 connect 하면 강제 갱신을 요청한다', () async {
      final settings = FakeChatSettings();
      final cubit = cubitOf(settings);
      await cubit.load();
      verifier
        ..result = const ModelListResult.unreachable()
        ..stored = (ChatVendor.anthropic, const ModelListResult.ok([sonnet]));

      final check = await cubit.check('sk-ant-api03-abcd5678');
      await cubit.connect('sk-ant-api03-abcd5678', check);
      await pumpEventQueue();

      expect(verifier.fetchStoredCalls, 1);
      expect(cubit.state.model?.label, 'Claude Sonnet 9.5');
      await cubit.close();
    });

    test('ok 확인 뒤 다시 unreachable 로 확인하면 앞 목록을 넣지 않는다', () async {
      final settings = FakeChatSettings();
      final cubit = cubitOf(settings);
      await cubit.load();
      verifier.result = const ModelListResult.ok([sonnet]);
      await cubit.check('sk-ant-api03-abcd5678');
      verifier.result = const ModelListResult.unreachable();

      final check = await cubit.check('sk-ant-api03-efgh9999');
      await cubit.connect('sk-ant-api03-efgh9999', check);
      await pumpEventQueue();

      expect(catalog.replaceCalls, isEmpty);
      await cubit.close();
    });

    test('disconnect 는 forget', () async {
      final settings = FakeChatSettings(key);
      await catalog.replace(ChatVendor.anthropic, [sonnet], DateTime.now());
      final cubit = cubitOf(settings);
      await cubit.load();

      await cubit.disconnect();

      expect(catalog.clearCalls, 1);
      expect(cubit.state.model, isNull);
      await cubit.close();
    });

    test('빠른 출력은 지원 모델에서 켜져 있을 때만', () async {
      final settings = FakeChatSettings(key)..fastMode = true;
      await catalog.replace(ChatVendor.anthropic, [sonnet], DateTime.now());
      final cubit = cubitOf(settings);
      await cubit.load();

      // 지원 표가 비어 있다(A2) — 켜 둬도 요청에 실리지 않는다.
      expect(cubit.state.fastMode, isFalse);
      await cubit.close();
    });
  });
}
