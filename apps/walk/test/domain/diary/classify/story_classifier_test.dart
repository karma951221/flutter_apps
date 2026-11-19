import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_connection.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_usage_log.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/diary/classify/story_classifier.dart';
import 'package:walk/domain/diary/classify/story_pick.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/usecase/story_suggestion.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_chat_model_catalog.dart';
import '../../../support/fake_chat_model_registry.dart';
import '../../../support/fake_chat_settings.dart';
import '../../../support/fake_chat_usage_log.dart';
import '../../../support/fake_diary_preferences.dart';

class _Ids implements IdGenerator {
  @override
  String newId() => 'q1';
}

/// 준비된 이벤트(또는 던질 오류)를 흘리고 받은 요청을 모은다. [hang] 이면 끝나지 않는다.
class _FakeModel implements ChatModel {
  _FakeModel(this.items, {this.hang = false});

  final List<Object> items;
  final bool hang;
  final requests = <ModelRequest>[];

  @override
  bool get progressNotes => false;

  @override
  ChatVendor get vendor => ChatVendor.anthropic;

  @override
  Future<ModelListResult> listModels(String apiKey) async =>
      const ModelListResult.ok([]);

  @override
  Stream<ModelEvent> stream(ModelRequest request) async* {
    requests.add(request);
    if (hang) await Completer<void>().future;
    for (final item in items) {
      if (item is ModelEvent) {
        yield item;
      } else {
        throw item;
      }
    }
  }
}

const _usage = TokenUsage(inputTokens: 300, outputTokens: 30);

List<Object> _answer(String text, {StopKind stop = StopKind.endTurn}) => [
  ModelEvent.textDelta(text),
  ModelEvent.completed(
    message: AssistantMessage(parts: [AssistantPart.text(text)]),
    stop: stop,
    usage: _usage,
  ),
];

const _haiku = 'claude-haiku-9-5';
const _sonnet = 'claude-sonnet-9-9';

void main() {
  late DiaryHarness h;
  late FakeChatSettings settings;
  late FakeChatModelCatalog catalog;
  late FakeDiaryPreferences prefs;
  late FakeChatUsageLog usage;
  late Story jeju;
  late Story closed;
  late List<Story> stories;

  setUp(() async {
    h = DiaryHarness();
    settings = FakeChatSettings('sk-ant-test-key')
      ..consentedVendor = ChatVendor.anthropic
      ..selectedModel = _sonnet;
    catalog = FakeChatModelCatalog();
    await catalog.replace(ChatVendor.anthropic, [
      ModelInfo(
        id: _sonnet,
        displayName: _sonnet,
        createdAt: DateTime.utc(2026, 1, 9),
      ),
      ModelInfo(
        id: _haiku,
        displayName: _haiku,
        createdAt: DateTime.utc(2026, 1, 5),
      ),
    ], h.clock.now());
    prefs = FakeDiaryPreferences();
    usage = FakeChatUsageLog();

    jeju = okValue(
      await h.repository.createStory(
        title: '제주 여행',
        startedAt: DateTime(2026, 10, 7),
      ),
    );
    okValue(
      await h.repository.createEntry(
        entryDraft(storyId: jeju.id, body: '협재 해변에서 노을'),
      ),
    );
    closed = okValue(
      await h.repository.createStory(
        title: '지난 여름',
        startedAt: DateTime(2026, 7),
        endedAt: DateTime(2026, 8),
      ),
    );
    stories = await h.repository.watchStories().first;
  });

  tearDown(() => h.close());

  StoryClassifier classifierOf(ChatModel model) => StoryClassifier(
    FakeChatModelRegistry({ChatVendor.anthropic: model}),
    settings,
    catalog,
    h.repository,
    prefs,
    usage,
    _Ids(),
    h.clock,
  );

  Future<StoryPick> classify(
    ChatModel model, {
    String body = '오늘 성산일출봉',
    String? fallbackId,
  }) => classifierOf(model).classify(
    entryDraft(body: body),
    stories,
    dailyTitle: '일상',
    fallbackId: fallbackId,
    locale: 'ko',
  );

  group('availability', () {
    test('키가 없으면 unavailable', () async {
      settings.key = null;
      expect(
        await classifierOf(_FakeModel([])).availability(),
        const StoryAiAvailability.unavailable(),
      );
    });

    test('키 저장소를 읽지 못하면 unavailable', () async {
      settings.failWith = StateError('keystore');
      expect(
        await classifierOf(_FakeModel([])).availability(),
        const StoryAiAvailability.unavailable(),
      );
    });

    test('일기 설정에서 껐으면 unavailable', () async {
      prefs.storyAiOff = true;
      expect(
        await classifierOf(_FakeModel([])).availability(),
        const StoryAiAvailability.unavailable(),
      );
    });

    test('물어보기 동의 · 이 기능 동의가 모두 없으면 needsConsent', () async {
      settings
        ..consentedVendor = null
        ..draftConsentedVendor = ChatVendor.anthropic;
      expect(
        await classifierOf(_FakeModel([])).availability(),
        const StoryAiAvailability.needsConsent(ChatVendor.anthropic),
      );

      prefs.storyAiVendor = ChatVendor.openai;
      expect(
        await classifierOf(_FakeModel([])).availability(),
        const StoryAiAvailability.needsConsent(ChatVendor.anthropic),
      );
    });

    test('이 기능 동의나 물어보기 동의가 있으면 ready', () async {
      expect(
        await classifierOf(_FakeModel([])).availability(),
        const StoryAiAvailability.ready(ChatVendor.anthropic),
      );

      settings.consentedVendor = null;
      prefs.storyAiVendor = ChatVendor.anthropic;
      expect(
        await classifierOf(_FakeModel([])).availability(),
        const StoryAiAvailability.ready(ChatVendor.anthropic),
      );
    });

    test('consent · decline 은 설정에 남긴다', () async {
      final c = classifierOf(_FakeModel([]));
      await c.consent(ChatVendor.openai);
      expect(prefs.storyAiVendor, ChatVendor.openai);
      await c.decline();
      expect(prefs.storyAiOff, isTrue);
    });
  });

  group('classify — 고른다', () {
    test('기존 스토리 id 면 existing, 요청은 초안 모델 · 도구 없음 · 생각 끔', () async {
      final model = _FakeModel(
        _answer('{"story_id": "${jeju.id}", "reason": "제주 이야기"}'),
      );

      final pick = await classify(model);

      expect(pick, StoryPick.existing(storyId: jeju.id, reason: '제주 이야기'));
      final r = model.requests.single;
      expect(r.model, _haiku);
      expect(r.tools, isEmpty);
      expect(r.thinking, isFalse);
      expect(r.maxOutputTokens, StoryClassifier.maxOutputTokens);
    });

    test('열린 스토리 이름 · 최근 기록만 싣는다(닫힌 스토리는 빼고)', () async {
      final model = _FakeModel(_answer('{"story_id": "daily"}'));

      await classify(model);

      final user = (model.requests.single.messages.single as UserMessage).text;
      expect(user, contains('제주 여행'));
      expect(user, contains('협재 해변에서 노을'));
      expect(user, contains('id: daily | 이름: 일상 (기본)'));
      expect(user, isNot(contains(closed.id)));
      expect(user, contains('오늘 성산일출봉'));
    });

    test('새 스토리 제안이면 create', () async {
      final pick = await classify(
        _FakeModel(_answer('{"new_story": "도쿄 출장", "reason": "새 여행"}')),
      );
      expect(pick, const StoryPick.create(title: '도쿄 출장', reason: '새 여행'));
    });

    test('사용량을 storyClassify 로 남긴다', () async {
      await classify(_FakeModel(_answer('{"story_id": "daily"}')));
      final record = usage.records.single;
      expect(record.purpose, ChatUsagePurpose.storyClassify);
      expect(record.model, _haiku);
      expect(record.inputTokens, 300);
    });
  });

  group('classify — 실패하면 기본값', () {
    test('없는 id 가 오면 fallback(주어진 기본값)', () async {
      final pick = await classify(
        _FakeModel(_answer('{"story_id": "tokyo", "reason": "?"}')),
        fallbackId: jeju.id,
      );
      expect(pick, StoryPick.fallback(jeju.id));
    });

    test('잘못된 답이면 fallback — 기본값을 주지 않으면 defaultFor', () async {
      final pick = await classify(_FakeModel(_answer('제주 여행 같아요')));
      expect(pick, StoryPick.fallback(StorySuggestion.defaultFor(stories)));
    });

    test('키가 없으면 부르지 않고 fallback', () async {
      settings.key = null;
      final model = _FakeModel(_answer('{"story_id": "daily"}'));
      expect(
        await classify(model, fallbackId: 'x'),
        const StoryPick.fallback('x'),
      );
      expect(model.requests, isEmpty);
    });

    test('동의가 없거나 꺼져 있으면 부르지 않고 fallback', () async {
      final model = _FakeModel(_answer('{"story_id": "daily"}'));
      settings
        ..consentedVendor = null
        ..draftConsentedVendor = null;
      expect(
        await classify(model, fallbackId: 'x'),
        const StoryPick.fallback('x'),
      );

      settings.consentedVendor = ChatVendor.anthropic;
      prefs.storyAiOff = true;
      expect(
        await classify(model, fallbackId: 'x'),
        const StoryPick.fallback('x'),
      );
      expect(model.requests, isEmpty);
    });

    test('본문이 비면 부르지 않고 fallback', () async {
      final model = _FakeModel(_answer('{"story_id": "daily"}'));
      expect(
        await classify(model, body: '  \n', fallbackId: 'x'),
        const StoryPick.fallback('x'),
      );
      expect(model.requests, isEmpty);
    });

    test('네트워크 오류면 fallback', () async {
      final pick = await classify(
        _FakeModel([const ChatModelException(ChatModelErrorKind.network)]),
        fallbackId: 'x',
      );
      expect(pick, const StoryPick.fallback('x'));
    });

    test('잘못된 키면 fallback, 키 상태를 invalid 로 남긴다', () async {
      final pick = await classify(
        _FakeModel([const ChatModelException(ChatModelErrorKind.invalidKey)]),
        fallbackId: 'x',
      );
      await pumpEventQueue();
      expect(pick, const StoryPick.fallback('x'));
      expect(settings.statusWrites, [ChatKeyStatus.invalid]);
    });

    test('예상하지 못한 오류 · 거절 · 완료 없는 끝이면 fallback', () async {
      expect(
        await classify(_FakeModel([StateError('boom')]), fallbackId: 'x'),
        const StoryPick.fallback('x'),
      );
      expect(
        await classify(
          _FakeModel(_answer('{"story_id": "daily"}', stop: StopKind.refusal)),
          fallbackId: 'x',
        ),
        const StoryPick.fallback('x'),
      );
      expect(
        await classify(
          _FakeModel([const ModelEvent.textDelta('{')]),
          fallbackId: 'x',
        ),
        const StoryPick.fallback('x'),
      );
    });

    test('timeout 안에 답이 없으면 fallback', () async {
      final c = classifierOf(_FakeModel(const [], hang: true))
        ..timeout = const Duration(milliseconds: 20);
      final pick = await c.classify(
        entryDraft(body: '오늘'),
        stories,
        dailyTitle: '일상',
        fallbackId: 'x',
      );
      expect(pick, const StoryPick.fallback('x'));
    });
  });
}
