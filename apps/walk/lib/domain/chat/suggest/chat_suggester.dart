import 'dart:async';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../chat_connection.dart';
import '../chat_model.dart';
import '../chat_model_catalog.dart';
import '../chat_model_rules.dart';
import '../chat_settings.dart';
import '../chat_usage_log.dart';
import '../chat_vendor.dart';
import '../entity/conversation.dart';
import '../repository/chat_history_repository.dart';
import 'chat_suggestion_store.dart';
import 'chat_suggestions.dart';
import 'suggest_prompt.dart';

/// [ChatSuggester] 한 번의 결과.
enum SuggestOutcome {
  /// 새 추천을 저장했다.
  generated,

  /// 조건이 맞지 않아 부르지 않았다.
  skipped,

  /// 불렀지만 쓸 만한 답을 받지 못했다 — 저장된 추천은 그대로다.
  failed,
}

/// 최근 질문으로 첫 화면 추천 질문을 만든다(스펙 2026-11-17).
///
/// [DraftWriter] 처럼 세션과 따로 돈다 — 연결 벤더의 초안 모델([draftModelOf])로 도구 · 생각 없이
/// 한 라운드, 출력은 [maxOutputTokens] 까지. 질문 글과 날짜만 보내므로 물어보기 동의
/// (`consentedVendor`) 범위 안이다. 던지지 않는다.
@lazySingleton
class ChatSuggester {
  ChatSuggester(
    this._registry,
    this._settings,
    this._catalog,
    this._history,
    this._store,
    this._usage,
    this._ids,
    this._clock,
  );

  final ChatModelRegistry _registry;
  final ChatSettings _settings;
  final ChatModelCatalog _catalog;
  final ChatHistoryRepository _history;
  final ChatSuggestionStore _store;
  final ChatUsageLog _usage;
  final IdGenerator _ids;
  final Clock _clock;

  static const maxOutputTokens = 200;

  /// 보내는 최근 질문 수.
  static const recentLimit = 20;

  /// 만들려면 있어야 하는 저장된 질문 수.
  static const minQuestions = 3;

  /// 마지막 생성 뒤 이만큼 새 질문이 쌓여야 저절로 다시 만든다.
  static const newQuestionsToRefresh = 5;

  /// 마지막 시도(실패 포함) 뒤 이만큼은 저절로 부르지 않는다.
  static const retryAfter = Duration(minutes: 10);

  Future<SuggestOutcome>? _running;

  /// 저장된 추천. 없으면 null.
  ChatSuggestions? get current => _store.current;

  /// 저장된 질문이 하나라도 있는가. 읽지 못하면 false.
  Future<bool> hasQuestions() async {
    try {
      return (await _history.recentQuestions(limit: 1)).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// 키 · 물어보기 동의 · 질문 [minQuestions] 개가 갖춰졌는가 — 새로 만들기를 보일지.
  Future<bool> canGenerate() async =>
      await _ready() != null && (await _recent()).length >= minQuestions;

  /// 조건이 맞으면 만든다. 화면이 빈 대화를 보일 때 부른다.
  Future<SuggestOutcome> refreshIfDue({String? locale}) =>
      _once(() => _generate(force: false, locale: locale));

  /// 새 질문 수 · 시도 간격을 보지 않고 만든다(새로 만들기).
  Future<SuggestOutcome> refresh({String? locale}) =>
      _once(() => _generate(force: true, locale: locale));

  Future<SuggestOutcome> _once(Future<SuggestOutcome> Function() run) {
    final running = _running;
    if (running != null) return running;
    final next = run().whenComplete(() => _running = null);
    return _running = next;
  }

  /// 키 · 동의가 있으면 (키, 벤더), 아니면 null.
  Future<(String, ChatVendor)?> _ready() async {
    final String? key;
    try {
      key = await _settings.apiKey();
    } catch (_) {
      return null;
    }
    final vendor = _settings.connectedVendor;
    if (key == null || vendor == null) return null;
    if (_settings.consentedVendor != vendor) return null;
    return (key, vendor);
  }

  Future<List<RecentQuestion>> _recent() async {
    try {
      return await _history.recentQuestions(limit: recentLimit);
    } catch (_) {
      return const [];
    }
  }

  Future<SuggestOutcome> _generate({
    required bool force,
    String? locale,
  }) async {
    final ready = await _ready();
    if (ready == null) return SuggestOutcome.skipped;
    final (apiKey, vendor) = ready;
    final recent = await _recent();
    if (recent.length < minQuestions) return SuggestOutcome.skipped;

    final now = _clock.now();
    if (!force && !_due(recent, now)) return SuggestOutcome.skipped;

    await _safe(() => _store.setTriedAt(now));
    final models = _catalog.vendor == vendor ? _catalog.models : <ModelInfo>[];
    final modelId = draftModelOf(vendor, models);
    final request = ModelRequest(
      apiKey: apiKey,
      model: modelId,
      system: SuggestPrompt.system(locale),
      messages: [ChatMessage.user(SuggestPrompt.user(recent, now))],
      tools: const [],
      maxOutputTokens: maxOutputTokens,
      thinking: false,
    );

    ModelCompleted? done;
    try {
      await for (final event in _registry.of(vendor).stream(request)) {
        if (event is ModelCompleted) done = event;
      }
    } on ChatModelException catch (e) {
      if (e.kind == ChatModelErrorKind.invalidKey) {
        unawaited(
          _safe(
            () => _settings.setKeyStatus(ChatKeyStatus.invalid, forKey: apiKey),
          ),
        );
      }
      return SuggestOutcome.failed;
    } catch (_) {
      return SuggestOutcome.failed;
    }
    if (done == null) return SuggestOutcome.failed;
    _recordUsage(vendor, modelId, done);
    if (done.stop == StopKind.refusal) return SuggestOutcome.failed;

    final text = done.message.parts.whereType<TextPart>().map((p) => p.text);
    final questions = SuggestPrompt.parse(text.join());
    if (questions.length < minQuestions) return SuggestOutcome.failed;
    final saved = await _safe(
      () => _store.save(
        ChatSuggestions(
          questions: questions,
          generatedAt: now,
          basedOnAskedAt: recent.first.askedAt,
        ),
      ),
    );
    return saved ? SuggestOutcome.generated : SuggestOutcome.failed;
  }

  /// 처음이거나 마지막 생성 뒤 새 질문이 [newQuestionsToRefresh] 개 이상이고, 마지막 시도에서
  /// [retryAfter] 가 지났는가.
  bool _due(List<RecentQuestion> recent, DateTime now) {
    final tried = _store.triedAt;
    if (tried != null && now.difference(tried) < retryAfter) return false;
    final current = _store.current;
    if (current == null) return true;
    final fresh = recent.where(
      (q) => q.askedAt.isAfter(current.basedOnAskedAt),
    );
    return fresh.length >= newQuestionsToRefresh;
  }

  /// 기다리지 않고 오류를 삼킨다.
  void _recordUsage(ChatVendor vendor, String model, ModelCompleted event) {
    final usage = event.usage;
    if (usage == null) return;
    final record = ChatUsageRecord(
      at: _clock.now(),
      questionKey: _ids.newId(),
      vendor: vendor,
      model: model,
      fastMode: false,
      purpose: ChatUsagePurpose.chatSuggest,
      round: 1,
      temporary: false,
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
      cacheReadTokens: usage.cacheReadTokens,
      cacheWriteTokens: usage.cacheWriteTokens,
      reasoningTokens: usage.reasoningTokens,
    );
    unawaited(_safe(() => _usage.record(record)));
  }

  static Future<bool> _safe(FutureOr<void> Function() run) async {
    try {
      await run();
      return true;
    } catch (_) {
      return false;
    }
  }
}
