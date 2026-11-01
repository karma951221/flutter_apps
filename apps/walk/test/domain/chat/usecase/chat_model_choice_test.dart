import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/chat/prefs_chat_model_catalog.dart';
import 'package:walk/domain/chat/chat_connection.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_model_rules.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/usecase/chat_model_choice.dart';

import '../../../support/diary_fixtures.dart' show MutableClock;
import '../../../support/fake_chat_key_verifier.dart';
import '../../../support/fake_chat_settings.dart';

ModelInfo _m(String id, int day) =>
    ModelInfo(id: id, displayName: id, createdAt: DateTime.utc(2026, 1, day));

final _opus = _m('claude-opus-9-9', 9);
final _sonnet = _m('claude-sonnet-9-5', 5);
final _haiku = _m('claude-haiku-9-1', 1);

void main() {
  final t0 = DateTime(2026, 11, 1, 9);

  late FakeChatSettings settings;
  late PrefsChatModelCatalog catalog;
  late FakeChatKeyVerifier verifier;
  late MutableClock clock;
  late ChatModelChoice choice;

  ChatModelChoice build({Map<ChatVendor, List<FastModeSpec>>? specs}) =>
      ChatModelChoice(settings, catalog, verifier, clock, fastModeSpecs: specs);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = FakeChatSettings('sk-ant-stored');
    catalog = PrefsChatModelCatalog(await SharedPreferences.getInstance());
    verifier = FakeChatKeyVerifier()
      ..stored = (
        ChatVendor.anthropic,
        ModelListResult.ok([_opus, _sonnet, _haiku]),
      );
    clock = MutableClock(t0);
    choice = build();
  });

  /// 목록을 [at] 에 받아 둔 상태.
  Future<void> seed({
    List<ModelInfo>? models,
    ChatVendor vendor = ChatVendor.anthropic,
    DateTime? at,
  }) => catalog.replace(vendor, models ?? [_opus, _sonnet, _haiku], at ?? t0);

  group('지금 모델', () {
    test('목록이 없으면 currentModel null', () {
      expect(choice.currentModel, isNull);
      expect(choice.currentInfo, isNull);
      expect(choice.usingRecommended, isFalse);
    });

    test('목록 벤더가 연결 벤더와 다르면 null', () async {
      await seed(models: [_m('gpt-9', 1)], vendor: ChatVendor.openai);

      expect(choice.currentModel, isNull);
      expect(choice.hasUnseenNewer, isFalse);
    });

    test('고른 모델이 없으면 추천', () async {
      await seed();

      expect(choice.currentModel, 'claude-sonnet-9-5');
      expect(choice.currentInfo, _sonnet);
      expect(choice.usingRecommended, isTrue);
    });

    test('고른 모델이 있으면 그것', () async {
      await seed();
      settings.selectedModel = 'claude-haiku-9-1';

      expect(choice.currentModel, 'claude-haiku-9-1');
      expect(choice.usingRecommended, isFalse);
    });

    test('고른 모델이 목록에 없으면 추천', () async {
      await seed();
      settings.selectedModel = 'claude-gone-1';

      expect(choice.currentModel, 'claude-sonnet-9-5');
    });

    test('hasUnseenNewer 는 지금 모델 기준', () async {
      await seed(models: [_sonnet, _haiku]);
      await seed(models: [_opus, _sonnet, _haiku]);

      expect(choice.hasUnseenNewer, isTrue);
      settings.selectedModel = 'claude-opus-9-9';
      expect(choice.hasUnseenNewer, isFalse);
    });

    test('supportsImages 는 지금 모델 기준', () async {
      await seed();
      expect(choice.supportsImages, isTrue);

      await choice.markNoImages('claude-sonnet-9-5');
      expect(choice.supportsImages, isFalse);
      settings.selectedModel = 'claude-opus-9-9';
      expect(choice.supportsImages, isTrue);
    });
  });

  group('select', () {
    test('select 가 추천과 같으면 null 로 저장한다', () async {
      await seed();

      await choice.select('claude-opus-9-9');
      expect(settings.selectedModel, 'claude-opus-9-9');

      await choice.select('claude-sonnet-9-5');
      expect(settings.selectedModel, isNull);
      expect(choice.currentModel, 'claude-sonnet-9-5');
    });
  });

  group('refresh', () {
    test('24시간 안이면 skipped, verifier 를 부르지 않음', () async {
      await seed();
      clock.advance(const Duration(hours: 23));

      expect(await choice.refresh(), const ModelsRefresh.skipped());
      expect(verifier.fetchStoredCalls, 0);
    });

    test('미연결이면 skipped, verifier 를 부르지 않음', () async {
      settings.key = null;

      expect(await choice.refresh(force: true), const ModelsRefresh.skipped());
      expect(verifier.fetchStoredCalls, 0);
    });

    test('목록이 없으면 받는다', () async {
      expect(
        await choice.refresh(),
        const ModelsRefresh.updated(replacedSelection: false),
      );
      expect(verifier.fetchStoredCalls, 1);
      expect(choice.currentModel, 'claude-sonnet-9-5');
      expect(catalog.fetchedAt, t0.toUtc());
    });

    test('넘었으면 받는다', () async {
      await seed(models: [_haiku]);
      clock.advance(const Duration(hours: 24));

      expect(
        await choice.refresh(),
        const ModelsRefresh.updated(replacedSelection: false),
      );
      expect(verifier.fetchStoredCalls, 1);
      expect(catalog.models, hasLength(3));
      expect(catalog.fetchedAt, clock.now().toUtc());
    });

    test('force 면 받는다', () async {
      await seed();

      await choice.refresh(force: true);

      expect(verifier.fetchStoredCalls, 1);
    });

    test('unverified 면 24시간 안이어도 받는다', () async {
      await seed();
      settings.status = ChatKeyStatus.unverified;

      await choice.refresh();

      expect(verifier.fetchStoredCalls, 1);
    });

    test('카탈로그 벤더가 연결 벤더와 다르면 받는다', () async {
      await seed(models: [_m('gpt-9', 1)], vendor: ChatVendor.openai);

      await choice.refresh();

      expect(verifier.fetchStoredCalls, 1);
      expect(catalog.vendor, ChatVendor.anthropic);
    });

    test('refresh 실패(unreachable)면 캐시 그대로', () async {
      await seed(models: [_haiku]);
      clock.advance(const Duration(days: 2));
      verifier.stored = (
        ChatVendor.anthropic,
        const ModelListResult.unreachable(),
      );

      expect(await choice.refresh(), const ModelsRefresh.unreachable());
      expect(catalog.models, [_haiku]);
      expect(catalog.fetchedAt, t0.toUtc());
    });

    test('verifier 가 던져도 unreachable · 캐시 그대로', () async {
      await seed(models: [_haiku]);
      verifier.fetchStoredError = StateError('boom');

      expect(
        await choice.refresh(force: true),
        const ModelsRefresh.unreachable(),
      );
      expect(catalog.models, [_haiku]);
    });

    test('invalidKey 면 ModelsInvalidKey', () async {
      await seed(models: [_haiku]);
      verifier.stored = (
        ChatVendor.anthropic,
        const ModelListResult.invalidKey(),
      );

      expect(
        await choice.refresh(force: true),
        const ModelsRefresh.invalidKey(),
      );
      expect(catalog.models, [_haiku]);
    });

    test('받는 동안 끊겨 verifier 가 null 이면 skipped', () async {
      verifier.stored = null;

      expect(await choice.refresh(force: true), const ModelsRefresh.skipped());
      expect(catalog.models, isEmpty);
    });

    test('거른 목록이 비면 캐시를 지우지 않는다', () async {
      await seed(models: [_haiku]);
      verifier.stored = (
        ChatVendor.anthropic,
        ModelListResult.ok([_m('not-a-claude', 1)]),
      );

      expect(
        await choice.refresh(force: true),
        const ModelsRefresh.unreachable(),
      );
      expect(catalog.models, [_haiku]);
    });

    test('받은 목록에 고른 모델이 없으면 추천으로 되돌리고 알림을 한 번 세운다', () async {
      await seed(models: [_opus, _sonnet, _haiku, _m('claude-old-1', 0)]);
      settings.selectedModel = 'claude-old-1';
      expect(choice.selectionReplacedNotice, isFalse);

      expect(
        await choice.refresh(force: true),
        const ModelsRefresh.updated(replacedSelection: true),
      );
      expect(settings.selectedModel, isNull);
      expect(choice.currentModel, 'claude-sonnet-9-5');
      expect(choice.selectionReplacedNotice, isTrue);

      choice.consumeSelectionReplacedNotice();
      expect(choice.selectionReplacedNotice, isFalse);

      // 다음 갱신에서 고른 모델이 없으면(추천을 따라가는 중) 다시 세우지 않는다.
      expect(
        await choice.refresh(force: true),
        const ModelsRefresh.updated(replacedSelection: false),
      );
      expect(choice.selectionReplacedNotice, isFalse);
    });
  });

  group('빠른 출력', () {
    final specs = {
      ChatVendor.anthropic: [
        FastModeSpec(pattern: RegExp(r'^claude-opus-'), priceFactor: 6),
      ],
    };

    test('fastModeOn 은 지원 모델 + 설정이 켜졌을 때만', () async {
      choice = build(specs: specs);
      await seed();

      // 추천(sonnet)은 지원하지 않는다.
      await choice.setFastMode(true);
      expect(settings.fastMode, isTrue);
      expect(choice.fastModeAvailable, isFalse);
      expect(choice.fastModeSpec, isNull);
      expect(choice.fastModeOn, isFalse);

      await choice.select('claude-opus-9-9');
      expect(choice.fastModeAvailable, isTrue);
      expect(choice.fastModeSpec?.priceFactor, 6);
      expect(choice.fastModeOn, isTrue);

      await choice.setFastMode(false);
      expect(choice.fastModeOn, isFalse);
    });

    test('기본 표(확인 전)는 비어 있어 늘 꺼짐', () async {
      await seed();
      settings.fastMode = true;
      await choice.select('claude-opus-9-9');

      expect(choice.fastModeAvailable, isFalse);
      expect(choice.fastModeOn, isFalse);
    });
  });

  group('recoverFromUnavailable', () {
    test('갱신 뒤 모델이 바뀌면 true', () async {
      await seed(models: [_opus, _sonnet, _haiku, _m('claude-old-1', 0)]);
      settings.selectedModel = 'claude-old-1';

      expect(await choice.recoverFromUnavailable('claude-old-1'), isTrue);
      expect(verifier.fetchStoredCalls, 1);
      expect(choice.currentModel, 'claude-sonnet-9-5');
    });

    test('같으면 false', () async {
      await seed();

      expect(await choice.recoverFromUnavailable('claude-sonnet-9-5'), isFalse);
      expect(verifier.fetchStoredCalls, 1);
    });

    test('갱신이 실패하면 false', () async {
      await seed();
      verifier.stored = (
        ChatVendor.anthropic,
        const ModelListResult.unreachable(),
      );

      expect(await choice.recoverFromUnavailable('claude-sonnet-9-5'), isFalse);
    });
  });

  group('adopt · forget', () {
    test('adopt 는 목록을 넣고 fetchedAt 을 지금으로', () async {
      clock.advance(const Duration(hours: 3));

      await choice.adopt(ChatVendor.anthropic, [_haiku, _sonnet]);

      expect(catalog.models, [_sonnet, _haiku]);
      expect(catalog.fetchedAt, clock.now().toUtc());
      expect(choice.currentModel, 'claude-sonnet-9-5');
      // 막 받았으니 다음 refresh 는 건너뛴다.
      expect(await choice.refresh(), const ModelsRefresh.skipped());
      expect(verifier.fetchStoredCalls, 0);
    });

    test('forget 은 비운다', () async {
      await seed();

      await choice.forget();

      expect(catalog.models, isEmpty);
      expect(catalog.vendor, isNull);
      expect(choice.currentModel, isNull);
    });
  });
}
