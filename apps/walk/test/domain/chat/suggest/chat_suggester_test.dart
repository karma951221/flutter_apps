import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:walk/domain/chat/chat_connection.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_usage_log.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/entity/conversation.dart';
import 'package:walk/domain/chat/repository/chat_history_repository.dart';
import 'package:walk/domain/chat/suggest/chat_suggester.dart';
import 'package:walk/domain/chat/suggest/chat_suggestion_store.dart';
import 'package:walk/domain/chat/suggest/chat_suggestions.dart';

import '../../../support/diary_fixtures.dart' show MutableClock;
import '../../../support/fake_chat_model_catalog.dart';
import '../../../support/fake_chat_model_registry.dart';
import '../../../support/fake_chat_settings.dart';
import '../../../support/fake_chat_usage_log.dart';

class _Ids extends IdGenerator {
  _Ids() : super(const Uuid());

  @override
  String newId() => 'q1';
}

/// 준비된 이벤트(또는 던질 오류)를 흘리고 받은 요청을 모은다.
class _FakeModel implements ChatModel {
  _FakeModel(this.items);

  List<Object> items;
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
    for (final item in items) {
      if (item is ModelEvent) {
        yield item;
      } else {
        throw item;
      }
    }
  }
}

class _Store implements ChatSuggestionStore {
  @override
  ChatSuggestions? current;

  @override
  DateTime? triedAt;

  @override
  Future<void> save(ChatSuggestions value) async => current = value;

  @override
  Future<void> setTriedAt(DateTime value) async => triedAt = value;
}

class _History implements ChatHistoryRepository {
  /// 최근 순.
  List<RecentQuestion> questions = [];
  final limits = <int>[];

  @override
  Future<List<RecentQuestion>> recentQuestions({required int limit}) async {
    limits.add(limit);
    return questions.take(limit).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _usage = TokenUsage(inputTokens: 300, outputTokens: 50);

List<Object> _answer(String text) => [
  ModelEvent.textDelta(text),
  ModelEvent.completed(
    message: AssistantMessage(parts: [AssistantPart.text(text)]),
    stop: StopKind.endTurn,
    usage: _usage,
  ),
];

const _haiku = 'claude-haiku-9-5';
const _sonnet = 'claude-sonnet-9-9';
const _reply = '어제 몇 걸음?\n이번 주 일기 요약\n요즘 자주 간 곳은?\n지난달 일찍 일어난 날?';

void main() {
  final t0 = DateTime(2026, 11, 17, 9);
  late MutableClock clock;
  late FakeChatSettings settings;
  late FakeChatModelCatalog catalog;
  late FakeChatUsageLog usage;
  late _Store store;
  late _History history;
  late _FakeModel model;

  /// [n] 개 질문, 가장 최근이 [latest], 1분 간격으로 거슬러.
  List<RecentQuestion> questions(int n, {DateTime? latest}) {
    final end = latest ?? t0.subtract(const Duration(minutes: 1));
    return [
      for (var i = 0; i < n; i++)
        (question: '질문 $i', askedAt: end.subtract(Duration(minutes: i))),
    ];
  }

  setUp(() async {
    clock = MutableClock(t0);
    settings = FakeChatSettings('sk-ant-test-key')
      ..consentedVendor = ChatVendor.anthropic
      ..selectedModel = _sonnet;
    catalog = FakeChatModelCatalog();
    await catalog.replace(ChatVendor.anthropic, [
      ModelInfo(id: _sonnet, displayName: _sonnet),
      ModelInfo(id: _haiku, displayName: _haiku),
    ], t0);
    usage = FakeChatUsageLog();
    store = _Store();
    history = _History()..questions = questions(3);
    model = _FakeModel(_answer(_reply));
  });

  ChatSuggester suggester() => ChatSuggester(
    FakeChatModelRegistry({ChatVendor.anthropic: model}),
    settings,
    catalog,
    history,
    store,
    usage,
    _Ids(),
    clock,
  );

  group('canGenerate', () {
    test('키 · 동의 · 질문 3개가 모두 있어야 true', () async {
      expect(await suggester().canGenerate(), isTrue);

      history.questions = questions(2);
      expect(await suggester().canGenerate(), isFalse);

      history.questions = questions(3);
      settings.consentedVendor = ChatVendor.openai;
      expect(await suggester().canGenerate(), isFalse);

      settings
        ..consentedVendor = ChatVendor.anthropic
        ..key = null;
      expect(await suggester().canGenerate(), isFalse);
    });
  });

  group('refreshIfDue', () {
    test('키가 없으면 부르지 않는다', () async {
      settings.key = null;

      expect(await suggester().refreshIfDue(), SuggestOutcome.skipped);
      expect(model.requests, isEmpty);
    });

    test('물어보기 동의가 연결 벤더와 다르면 부르지 않는다(초안 동의만으로는 안 된다)', () async {
      settings
        ..consentedVendor = null
        ..draftConsentedVendor = ChatVendor.anthropic;

      expect(await suggester().refreshIfDue(), SuggestOutcome.skipped);
      expect(model.requests, isEmpty);
    });

    test('저장된 질문이 3개 미만이면 부르지 않는다', () async {
      history.questions = questions(2);

      expect(await suggester().refreshIfDue(), SuggestOutcome.skipped);
      expect(model.requests, isEmpty);
    });

    test('처음엔 질문 3개면 초안 모델로 한 라운드 불러 4개를 저장하고 사용량을 남긴다', () async {
      final outcome = await suggester().refreshIfDue(locale: 'ko');

      expect(outcome, SuggestOutcome.generated);
      final request = model.requests.single;
      expect(request.model, _haiku);
      expect(request.tools, isEmpty);
      expect(request.thinking, isFalse);
      expect(request.maxOutputTokens, ChatSuggester.maxOutputTokens);
      expect(ChatSuggester.maxOutputTokens, 200);
      expect(history.limits.last, ChatSuggester.recentLimit);
      expect(ChatSuggester.recentLimit, 20);

      expect(store.current, isNotNull);
      expect(store.current!.questions, [
        '어제 몇 걸음?',
        '이번 주 일기 요약',
        '요즘 자주 간 곳은?',
        '지난달 일찍 일어난 날?',
      ]);
      expect(store.current!.generatedAt, t0);
      expect(store.current!.basedOnAskedAt, history.questions.first.askedAt);
      expect(store.triedAt, t0);

      final record = usage.records.single;
      expect(record.purpose, ChatUsagePurpose.chatSuggest);
      expect(record.model, _haiku);
      expect(record.inputTokens, 300);
    });

    test('마지막 생성 뒤 새 질문이 4개면 건너뛰고 5개면 다시 만든다', () async {
      final based = t0.subtract(const Duration(hours: 1));
      store.current = ChatSuggestions(
        questions: const ['옛 추천'],
        generatedAt: based,
        basedOnAskedAt: based,
      );
      store.triedAt = based;
      history.questions = [
        ...questions(4),
        ...questions(3, latest: based.subtract(const Duration(minutes: 5))),
      ];

      expect(await suggester().refreshIfDue(), SuggestOutcome.skipped);
      expect(model.requests, isEmpty);

      history.questions = [
        ...questions(5),
        ...questions(3, latest: based.subtract(const Duration(minutes: 5))),
      ];
      expect(await suggester().refreshIfDue(), SuggestOutcome.generated);
    });

    test('마지막 시도에서 10분이 안 지났으면 건너뛴다 — 실패가 반복돼도 매번 부르지 않는다', () async {
      model.items = [const ChatModelException(ChatModelErrorKind.network)];

      expect(await suggester().refreshIfDue(), SuggestOutcome.failed);
      clock.advance(const Duration(minutes: 9));
      expect(await suggester().refreshIfDue(), SuggestOutcome.skipped);
      expect(model.requests, hasLength(1));

      clock.advance(const Duration(minutes: 1));
      model.items = _answer(_reply);
      expect(await suggester().refreshIfDue(), SuggestOutcome.generated);
    });

    test('파싱된 질문이 3개 미만이면 실패이고 저장된 추천을 그대로 둔다', () async {
      final old = ChatSuggestions(
        questions: const ['옛 추천'],
        generatedAt: t0.subtract(const Duration(days: 1)),
        basedOnAskedAt: t0.subtract(const Duration(days: 1)),
      );
      store.current = old;
      history.questions = questions(5);
      model.items = _answer('하나?\n둘?');

      expect(await suggester().refreshIfDue(), SuggestOutcome.failed);
      expect(store.current, old);
    });

    test('잘못된 키 오류면 실패이고 키 상태를 invalid 로 남긴다', () async {
      model.items = [const ChatModelException(ChatModelErrorKind.invalidKey)];

      expect(await suggester().refreshIfDue(), SuggestOutcome.failed);
      await pumpEventQueue();
      expect(settings.statusWrites, [ChatKeyStatus.invalid]);
    });
  });

  group('refresh', () {
    test('새 질문 수 · 10분 조건 없이 바로 만든다', () async {
      final s = suggester();
      expect(await s.refreshIfDue(), SuggestOutcome.generated);

      expect(await s.refresh(), SuggestOutcome.generated);
      expect(model.requests, hasLength(2));
    });

    test('키 · 동의 · 질문 3개 조건은 그대로', () async {
      history.questions = questions(2);

      expect(await suggester().refresh(), SuggestOutcome.skipped);
      expect(model.requests, isEmpty);
    });

    test('만드는 중에 다시 부르면 같은 결과를 기다린다(요청은 하나)', () async {
      final s = suggester();
      final results = await Future.wait([s.refresh(), s.refreshIfDue()]);

      expect(results, [SuggestOutcome.generated, SuggestOutcome.generated]);
      expect(model.requests, hasLength(1));
    });
  });

  test('hasQuestions 는 저장된 질문이 하나라도 있으면 true', () async {
    expect(await suggester().hasQuestions(), isTrue);
    history.questions = [];
    expect(await suggester().hasQuestions(), isFalse);
  });
}
