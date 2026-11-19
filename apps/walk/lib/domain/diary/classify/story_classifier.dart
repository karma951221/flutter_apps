import 'dart:async';

import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../chat/chat_connection.dart';
import '../../chat/chat_model.dart';
import '../../chat/chat_model_catalog.dart';
import '../../chat/chat_model_rules.dart';
import '../../chat/chat_settings.dart';
import '../../chat/chat_usage_log.dart';
import '../../chat/chat_vendor.dart';
import '../entity/entry_draft.dart';
import '../entity/entry_filter.dart';
import '../entity/story.dart';
import '../repository/diary_preferences.dart';
import '../repository/diary_repository.dart';
import '../usecase/story_order.dart';
import '../usecase/story_suggestion.dart';
import 'story_classify_prompt.dart';
import 'story_pick.dart';

part 'story_classifier.freezed.dart';

/// 저장할 때 AI 스토리 고르기를 할 수 있는가 — 키 · 설정 · 동의 상태.
@freezed
sealed class StoryAiAvailability with _$StoryAiAvailability {
  /// 키가 없거나 일기 설정에서 껐다 — 조용히 기본값으로 저장한다.
  const factory StoryAiAvailability.unavailable() = StoryAiUnavailable;

  /// [vendor] 로의 전송 동의가 없다 — 저장할 때 한 번 묻는다.
  const factory StoryAiAvailability.needsConsent(ChatVendor vendor) =
      StoryAiConsentNeeded;

  /// [vendor] 로 보낼 수 있다.
  const factory StoryAiAvailability.ready(ChatVendor vendor) = StoryAiReady;
}

/// 새 일기를 넣을 스토리를 AI 로 고른다(스펙 2026-11-19).
///
/// [DraftWriter] 처럼 세션과 따로 돈다 — 연결 벤더의 초안 모델([draftModelOf])로 도구 · 생각 없이
/// 한 라운드. 열린 스토리의 이름과 최근 기록 [samplesPerStory] 개의 앞부분, 새 일기의 시각 · 장소 이름 ·
/// 태그 · 본문을 보낸다. **던지지 않는다** — 무엇이든 실패하면 [StoryPick.fallback] 이다.
@lazySingleton
class StoryClassifier {
  StoryClassifier(
    this._registry,
    this._settings,
    this._catalog,
    this._repo,
    this._prefs,
    this._usage,
    this._ids,
    this._clock,
  );

  final ChatModelRegistry _registry;
  final ChatSettings _settings;
  final ChatModelCatalog _catalog;
  final DiaryRepository _repo;
  final DiaryPreferences _prefs;
  final ChatUsageLog _usage;
  final IdGenerator _ids;
  final Clock _clock;

  static const maxOutputTokens = 200;

  /// 저장을 이보다 오래 붙잡지 않는다 — 넘으면 기본값.
  static const defaultTimeout = Duration(seconds: 10);

  /// [defaultTimeout]. 테스트만 줄인다.
  Duration timeout = defaultTimeout;

  /// 보내는 열린 스토리 수(StoryOrder 순 앞쪽).
  static const maxStories = 20;

  /// 스토리마다 보내는 최근 기록 수.
  static const samplesPerStory = 3;

  /// 키 · 설정 · 동의. 던지지 않는다 — 키 저장소를 읽지 못하면 unavailable.
  ///
  /// 동의는 이 기능의 동의([DiaryPreferences.storyAiVendor]) 또는 물어보기 동의
  /// ([ChatSettings.consentedVendor], 일기를 읽는 도구까지 품는다) 중 하나면 된다.
  Future<StoryAiAvailability> availability() async {
    if (_prefs.storyAiOff) return const StoryAiAvailability.unavailable();
    final bool hasKey;
    try {
      hasKey = await _settings.hasApiKey();
    } catch (_) {
      return const StoryAiAvailability.unavailable();
    }
    final vendor = _settings.connectedVendor;
    if (!hasKey || vendor == null) {
      return const StoryAiAvailability.unavailable();
    }
    if (_prefs.storyAiVendor != vendor && _settings.consentedVendor != vendor) {
      return StoryAiAvailability.needsConsent(vendor);
    }
    return StoryAiAvailability.ready(vendor);
  }

  /// 첫 사용 동의 — [vendor] 로 보내도 된다.
  Future<void> consent(ChatVendor vendor) => _prefs.setStoryAiVendor(vendor);

  /// 첫 사용 동의에서 '안 함' — 끈다(일기 설정에서 다시 켠다).
  Future<void> decline() => _prefs.setStoryAiOff(true);

  /// [draft] 를 넣을 열린 스토리를 [stories] 중에서 고르거나 새 스토리를 제안한다.
  ///
  /// 준비가 안 됐거나(키 · 동의 · 꺼짐) 본문이 비었거나 호출 · 파싱이 실패하면
  /// [StoryPick.fallback]([fallbackId], 없으면 [StorySuggestion.defaultFor]).
  /// [dailyTitle] 은 이름이 빈 기본 스토리를 부를 이름. 던지지 않는다.
  Future<StoryPick> classify(
    EntryDraft draft,
    List<Story> stories, {
    required String dailyTitle,
    String? fallbackId,
    String? locale,
  }) async {
    final fallback = StoryPick.fallback(
      fallbackId ?? StorySuggestion.defaultFor(stories),
    );
    if (draft.body.trim().isEmpty) return fallback;
    try {
      final pick = await _classify(
        draft,
        stories,
        dailyTitle: dailyTitle,
        locale: locale,
      ).timeout(timeout);
      return pick ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<StoryPick?> _classify(
    EntryDraft draft,
    List<Story> stories, {
    required String dailyTitle,
    String? locale,
  }) async {
    if (await availability() is! StoryAiReady) return null;
    final apiKey = await _settings.apiKey();
    final vendor = _settings.connectedVendor;
    if (apiKey == null || vendor == null) return null;

    final candidates = await _candidates(stories);
    final models = _catalog.vendor == vendor ? _catalog.models : <ModelInfo>[];
    final modelId = draftModelOf(vendor, models);
    final request = ModelRequest(
      apiKey: apiKey,
      model: modelId,
      system: StoryClassifyPrompt.system(locale),
      messages: [
        ChatMessage.user(
          StoryClassifyPrompt.user(draft, candidates, dailyTitle: dailyTitle),
        ),
      ],
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
      return null;
    }
    if (done == null) return null;
    _recordUsage(vendor, modelId, done);
    if (done.stop == StopKind.refusal) return null;
    final text = done.message.parts.whereType<TextPart>().map((p) => p.text);
    return StoryClassifyPrompt.parse(
      text.join(),
      candidates,
      dailyTitle: dailyTitle,
    );
  }

  /// 열린 스토리(StoryOrder 순) 앞 [maxStories] 개와 최근 기록 본문. 기본 스토리는 늘 넣는다.
  /// 기록을 읽지 못하면 이름만 보낸다.
  Future<List<StoryCandidate>> _candidates(List<Story> stories) async {
    final open = StoryOrder.split(stories).open.take(maxStories).toList();
    if (!open.any((s) => s.isDefault)) {
      final daily = stories.where((s) => s.isDefault).firstOrNull;
      if (daily != null) open.add(daily);
    }
    return [
      for (final story in open)
        StoryCandidate(story: story, samples: await _samples(story.id)),
    ];
  }

  Future<List<String>> _samples(String storyId) async {
    try {
      final entries = await _repo
          .watchEntries(EntryFilter.story(storyId))
          .first;
      return [
        for (final e in entries)
          if (e.body.trim().isNotEmpty) e.body,
      ].take(samplesPerStory).toList();
    } catch (_) {
      return const [];
    }
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
      purpose: ChatUsagePurpose.storyClassify,
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

  static Future<void> _safe(FutureOr<void> Function() run) async {
    try {
      await run();
    } catch (_) {}
  }
}
