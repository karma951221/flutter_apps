import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_connection.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/usecase/chat_key_verifier.dart';

import '../../../support/fake_chat_model_registry.dart';
import '../../../support/fake_chat_settings.dart';

/// [listModels] 가 [next] 를 돌려준다(함수면 불러서). 받은 키를 기록한다.
class _ListModel implements ChatModel {
  @override
  bool get progressNotes => false;

  _ListModel(this.next, {this.vendor = ChatVendor.anthropic});

  FutureOr<ModelListResult> Function() next;
  final keys = <String>[];

  @override
  final ChatVendor vendor;

  @override
  Stream<ModelEvent> stream(ModelRequest request) => const Stream.empty();

  @override
  Future<ModelListResult> listModels(String apiKey) async {
    keys.add(apiKey);
    return next();
  }
}

ChatModelRegistry _registry(ChatModel model) =>
    FakeChatModelRegistry({model.vendor: model});

void main() {
  late FakeChatSettings settings;

  setUp(() {
    settings = FakeChatSettings('sk-ant-stored')
      ..status = ChatKeyStatus.unverified;
  });

  group('verify', () {
    test('verify 는 모델 결과를 그대로 준다', () async {
      for (final result in const [
        ModelListResult.ok([ModelInfo(id: 'a', displayName: 'A')]),
        ModelListResult.invalidKey(),
        ModelListResult.unreachable(),
      ]) {
        final model = _ListModel(() => result);
        expect(
          await ChatKeyVerifier(
            _registry(model),
            settings,
          ).verify(ChatVendor.anthropic, 'sk-new'),
          result,
        );
        expect(model.keys, ['sk-new']);
      }
      expect(settings.apiKeyCalls, 0);
    });

    test('verify 는 모델이 던지면 unreachable', () async {
      final model = _ListModel(() => throw StateError('boom'));
      expect(
        await ChatKeyVerifier(
          _registry(model),
          settings,
        ).verify(ChatVendor.anthropic, 'k'),
        const ModelListResult.unreachable(),
      );
    });

    test('verify 는 10초를 넘기면 unreachable', () {
      fakeAsync((async) {
        final model = _ListModel(() => Completer<ModelListResult>().future);
        ModelListResult? result;
        ChatKeyVerifier(
          _registry(model),
          settings,
        ).verify(ChatVendor.anthropic, 'k').then((r) => result = r);

        async.elapse(const Duration(seconds: 9));
        expect(result, isNull);
        async.elapse(const Duration(seconds: 2));
        expect(result, const ModelListResult.unreachable());
      });
    });

    test('verify 는 그 벤더 어댑터의 listModels 를 부른다', () async {
      final claude = _ListModel(() => const ModelListResult.invalidKey());
      final gpt = _ListModel(
        () => const ModelListResult.ok([]),
        vendor: ChatVendor.openai,
      );
      final verifier = ChatKeyVerifier(
        FakeChatModelRegistry({
          ChatVendor.anthropic: claude,
          ChatVendor.openai: gpt,
        }),
        settings,
      );

      expect(
        await verifier.verify(ChatVendor.openai, 'sk-gpt'),
        const ModelListResult.ok([]),
      );
      expect(gpt.keys, ['sk-gpt']);
      expect(claude.keys, isEmpty);

      expect(
        await verifier.verify(ChatVendor.anthropic, 'sk-ant'),
        const ModelListResult.invalidKey(),
      );
      expect(claude.keys, ['sk-ant']);
    });

    test('verify 는 어댑터가 없는 벤더면 unreachable', () async {
      final model = _ListModel(() => const ModelListResult.ok([]));
      expect(
        await ChatKeyVerifier(
          FakeChatModelRegistry({ChatVendor.anthropic: model}),
          settings,
        ).verify(ChatVendor.openai, 'k'),
        const ModelListResult.unreachable(),
      );
      expect(model.keys, isEmpty);
    });
  });

  group('fetchStored', () {
    const listed = [ModelInfo(id: 'claude-sonnet-9-9', displayName: 'S')];

    test('미연결이면 null · 모델을 부르지 않음', () async {
      settings.key = null;
      final model = _ListModel(() => const ModelListResult.ok(listed));

      expect(
        await ChatKeyVerifier(_registry(model), settings).fetchStored(),
        isNull,
      );
      expect(model.keys, isEmpty);
      expect(settings.apiKeyCalls, 0);
    });

    test('ok → valid 기록하고 (vendor, ok)', () async {
      final model = _ListModel(() => const ModelListResult.ok(listed));

      expect(await ChatKeyVerifier(_registry(model), settings).fetchStored(), (
        ChatVendor.anthropic,
        const ModelListResult.ok(listed),
      ));
      expect(model.keys, ['sk-ant-stored']);
      expect(settings.status, ChatKeyStatus.valid);
    });

    test('연결된 벤더의 어댑터를 부른다', () async {
      settings.vendor = ChatVendor.openai;
      final claude = _ListModel(() => const ModelListResult.ok([]));
      final gpt = _ListModel(
        () => const ModelListResult.ok(listed),
        vendor: ChatVendor.openai,
      );

      final got = await ChatKeyVerifier(
        FakeChatModelRegistry({
          ChatVendor.anthropic: claude,
          ChatVendor.openai: gpt,
        }),
        settings,
      ).fetchStored();

      expect(got?.$1, ChatVendor.openai);
      expect(gpt.keys, ['sk-ant-stored']);
      expect(claude.keys, isEmpty);
    });

    test('invalidKey → invalid', () async {
      settings.status = ChatKeyStatus.valid;
      final model = _ListModel(() => const ModelListResult.invalidKey());

      expect(await ChatKeyVerifier(_registry(model), settings).fetchStored(), (
        ChatVendor.anthropic,
        const ModelListResult.invalidKey(),
      ));
      expect(settings.status, ChatKeyStatus.invalid);
    });

    test('unreachable → 상태 그대로', () async {
      final model = _ListModel(() => const ModelListResult.unreachable());

      expect(await ChatKeyVerifier(_registry(model), settings).fetchStored(), (
        ChatVendor.anthropic,
        const ModelListResult.unreachable(),
      ));
      expect(settings.status, ChatKeyStatus.unverified);
      expect(settings.statusWrites, isEmpty);
    });

    test('30초를 넘기면 unreachable(10초 상한이 아니다)', () {
      fakeAsync((async) {
        final model = _ListModel(() => Completer<ModelListResult>().future);
        (ChatVendor, ModelListResult)? got;
        ChatKeyVerifier(
          _registry(model),
          settings,
        ).fetchStored().then((r) => got = r);

        async.elapse(const Duration(seconds: 29));
        expect(got, isNull);
        async.elapse(const Duration(seconds: 2));
        expect(got, (
          ChatVendor.anthropic,
          const ModelListResult.unreachable(),
        ));
      });
    });

    test('받는 동안 키를 바꾸거나 끊으면 기록하지 않고 null', () async {
      for (final change in ['바꿈', '끊음']) {
        settings
          ..key = 'sk-ant-stored'
          ..status = ChatKeyStatus.unverified
          ..statusWrites.clear();
        final gate = Completer<ModelListResult>();
        final model = _ListModel(() => gate.future);
        final pending = ChatKeyVerifier(
          _registry(model),
          settings,
        ).fetchStored();
        await pumpEventQueue();
        expect(model.keys, ['sk-ant-stored']);

        if (change == '바꿈') {
          await settings.connect(
            ChatVendor.anthropic,
            'sk-ant-other',
            ChatKeyStatus.unverified,
          );
        } else {
          await settings.disconnect();
        }
        gate.complete(const ModelListResult.invalidKey());

        expect(await pending, isNull, reason: change);
        expect(settings.statusWrites, isEmpty, reason: change);
      }
    });

    test('설정을 읽지 못하면 null · 상태 기록이 실패해도 결과는 준다', () async {
      final model = _ListModel(() => const ModelListResult.ok(listed));
      final verifier = ChatKeyVerifier(_registry(model), settings);

      settings.failSetKeyStatusWith = StateError('prefs');
      expect(await verifier.fetchStored(), (
        ChatVendor.anthropic,
        const ModelListResult.ok(listed),
      ));

      settings.failWith = StateError('keystore');
      expect(await verifier.fetchStored(), isNull);
    });

    test('동시에 두 번이면 listModels 한 번', () async {
      final gate = Completer<ModelListResult>();
      final model = _ListModel(() => gate.future);
      final verifier = ChatKeyVerifier(_registry(model), settings);

      final a = verifier.fetchStored();
      final b = verifier.fetchStored();
      await pumpEventQueue();
      gate.complete(const ModelListResult.ok(listed));

      expect(await a, (ChatVendor.anthropic, const ModelListResult.ok(listed)));
      expect(await b, await a);
      expect(model.keys, hasLength(1));

      // 끝난 뒤에는 다시 부른다.
      model.next = () => const ModelListResult.ok([]);
      await verifier.fetchStored();
      expect(model.keys, hasLength(2));
    });
  });
}
