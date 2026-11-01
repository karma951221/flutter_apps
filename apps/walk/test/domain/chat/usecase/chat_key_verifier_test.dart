import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_connection.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/usecase/chat_key_verifier.dart';

import '../../../support/fake_chat_settings.dart';

/// [listModels] 가 [next] 를 돌려준다(함수면 불러서). 받은 키를 기록한다.
class _ListModel implements ChatModel {
  _ListModel(this.next);

  FutureOr<ModelListResult> Function() next;
  final keys = <String>[];

  @override
  ChatVendor get vendor => ChatVendor.anthropic;

  @override
  Stream<ModelEvent> stream(ModelRequest request) => const Stream.empty();

  @override
  Future<ModelListResult> listModels(String apiKey) async {
    keys.add(apiKey);
    return next();
  }
}

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
            model,
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
          model,
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
          model,
          settings,
        ).verify(ChatVendor.anthropic, 'k').then((r) => result = r);

        async.elapse(const Duration(seconds: 9));
        expect(result, isNull);
        async.elapse(const Duration(seconds: 2));
        expect(result, const ModelListResult.unreachable());
      });
    });

    test('verify 는 다른 벤더면 ArgumentError', () {
      final model = _ListModel(() => const ModelListResult.ok([]));
      expect(
        () => ChatKeyVerifier(model, settings).verify(ChatVendor.openai, 'k'),
        throwsArgumentError,
      );
      expect(model.keys, isEmpty);
    });
  });

  group('recheckIfUnverified', () {
    test('unverified + ok 면 valid 를 기록한다', () async {
      final model = _ListModel(() => const ModelListResult.ok([]));
      expect(
        await ChatKeyVerifier(model, settings).recheckIfUnverified(),
        ChatKeyStatus.valid,
      );
      expect(model.keys, ['sk-ant-stored']);
      expect(settings.status, ChatKeyStatus.valid);
    });

    test('unverified + invalidKey 면 invalid 를 기록한다', () async {
      final model = _ListModel(() => const ModelListResult.invalidKey());
      expect(
        await ChatKeyVerifier(model, settings).recheckIfUnverified(),
        ChatKeyStatus.invalid,
      );
      expect(settings.status, ChatKeyStatus.invalid);
    });

    test('unverified + unreachable 이면 그대로 두고 null', () async {
      final model = _ListModel(() => const ModelListResult.unreachable());
      expect(
        await ChatKeyVerifier(model, settings).recheckIfUnverified(),
        isNull,
      );
      expect(settings.status, ChatKeyStatus.unverified);
      expect(settings.statusWrites, isEmpty);
    });

    test('valid · invalid · 미연결이면 모델을 부르지 않고 null', () async {
      final model = _ListModel(() => const ModelListResult.ok([]));
      final verifier = ChatKeyVerifier(model, settings);

      for (final status in [ChatKeyStatus.valid, ChatKeyStatus.invalid]) {
        settings.status = status;
        expect(await verifier.recheckIfUnverified(), isNull);
      }
      settings
        ..key = null
        ..status = ChatKeyStatus.unverified;
      expect(await verifier.recheckIfUnverified(), isNull);

      expect(model.keys, isEmpty);
      expect(settings.apiKeyCalls, 0);
      expect(settings.statusWrites, isEmpty);
    });

    test('동시에 두 번 불러도 모델은 한 번', () async {
      final gate = Completer<ModelListResult>();
      final model = _ListModel(() => gate.future);
      final verifier = ChatKeyVerifier(model, settings);

      final a = verifier.recheckIfUnverified();
      final b = verifier.recheckIfUnverified();
      await pumpEventQueue();
      gate.complete(const ModelListResult.ok([]));

      expect(await a, ChatKeyStatus.valid);
      expect(await b, ChatKeyStatus.valid);
      expect(model.keys, hasLength(1));

      // 끝난 뒤에는 다시 부를 수 있다(이제 valid 라 모델은 부르지 않는다).
      expect(await verifier.recheckIfUnverified(), isNull);
      expect(model.keys, hasLength(1));
    });
  });
}
