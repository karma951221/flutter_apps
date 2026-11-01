import 'dart:async';
import 'dart:convert';

import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

import '../../diary/repository/diary_repository.dart';
import '../chat_history_settings.dart';
import '../chat_model.dart';
import '../chat_settings.dart';
import '../chat_usage_log.dart';
import '../entity/conversation.dart';
import '../entity/wiki_note.dart';
import '../repository/chat_history_repository.dart';
import '../repository/wiki_repository.dart';
import '../tool/tool_result.dart';
import '../tool/wiki_tools.dart';
import '../wiki/wiki_index.dart';
import 'chat_model_choice.dart';
import 'chat_session.dart';

part 'wiki_distiller.freezed.dart';

/// [WikiDistiller.distill] 의 결과. toString 은 [WikiCandidate] 의 것이라 글을 담지 않는다.
@freezed
sealed class WikiDistillResult with _$WikiDistillResult {
  /// 걸러진 후보(0~8개). 0 개면 화면이 "남길 내용이 없어요".
  const factory WikiDistillResult.candidates(List<WikiCandidate> candidates) =
      WikiDistillCandidates;

  /// 키 없음 · 잘못된 키 · 네트워크 등 — 물어보기와 같은 실패 종류.
  const factory WikiDistillResult.failed(ChatFailure failure) =
      WikiDistillFailed;

  /// 응답을 JSON 후보로 읽지 못함 → "정리하지 못했어요".
  const factory WikiDistillResult.unparsable() = WikiDistillUnparsable;

  /// [WikiDistiller.cancel] 로 멈췄다. 화면은 아무것도 알리지 않는다.
  const factory WikiDistillResult.cancelled() = WikiDistillCancelled;
}

/// [위키로 정리](D6) — 저장된 대화에서 위키 후보를 뽑는 요청.
///
/// 세션과 따로 돈다(W4) — 세션의 세대 · busy 를 건드리지 않고 원문 키를 직접 읽는다.
/// 대화는 user 메시지 하나의 글로 묶는다(W5). 일기 도구는 싣지 않고 read_wiki 만.
/// 후보 본문의 링크는 이 대화의 근거 일기 · 지금 있는 메모만 남긴다.
@lazySingleton
class WikiDistiller {
  WikiDistiller(
    this._registry,
    this._settings,
    this._choice,
    this._historySettings,
    this._history,
    this._wiki,
    this._wikiTools,
    this._diary,
    this._usage,
    this._ids,
    this._clock,
  );

  final ChatModelRegistry _registry;
  final ChatSettings _settings;
  final ChatModelChoice _choice;
  final ChatHistorySettings _historySettings;
  final ChatHistoryRepository _history;
  final WikiRepository _wiki;
  final WikiTools _wikiTools;
  final DiaryRepository _diary;
  final ChatUsageLog _usage;
  final IdGenerator _ids;
  final Clock _clock;

  static const maxCandidates = 8;
  static const maxRounds = 4;

  /// 진행 중인 요청들. [cancel] 이 모두 끊는다.
  final _runs = <_Run>{};

  /// 진행 중인 정리 요청을 모두 멈춘다. 그 [distill] 은 cancelled 로 끝나고
  /// 모델 구독을 끊어 HTTP 를 닫는다(어댑터 몫).
  void cancel() {
    for (final run in [..._runs]) {
      run.cancel();
    }
  }

  /// [target] 은 지금 고른 벤더 · 모델(D6). 없으면 연결 벤더와 [ChatModelChoice.currentModel].
  Future<WikiDistillResult> distill({
    required String conversationId,
    ChatTarget? target,
  }) async {
    final run = _Run();
    _runs.add(run);
    try {
      return await _distill(conversationId, target, run);
    } on ChatModelException catch (e) {
      if (run.cancelled) return const WikiDistillResult.cancelled();
      return WikiDistillResult.failed(_failureOf(e.kind));
    } catch (_) {
      if (run.cancelled) return const WikiDistillResult.cancelled();
      return const WikiDistillResult.failed(ChatFailure.unknown);
    } finally {
      _runs.remove(run);
    }
  }

  Future<WikiDistillResult> _distill(
    String conversationId,
    ChatTarget? requested,
    _Run run,
  ) async {
    const cancelled = WikiDistillResult.cancelled();
    final apiKey = await _settings.apiKey();
    if (run.cancelled) return cancelled;
    if (apiKey == null) {
      return const WikiDistillResult.failed(ChatFailure.noKey);
    }
    final target = requested ?? _currentTarget();
    if (target == null) {
      return const WikiDistillResult.failed(ChatFailure.noModels);
    }

    final turns = await _history.turns(conversationId);
    if (run.cancelled) return cancelled;
    final recent = turns.length > ChatSession.resumeTurns
        ? turns.sublist(turns.length - ChatSession.resumeTurns)
        : turns;
    if (recent.isEmpty) return const WikiDistillResult.candidates([]);

    final dates = <String, String?>{};
    for (final turn in recent) {
      for (final id in turn.citedEntryIds) {
        if (!dates.containsKey(id)) dates[id] = await _diaryDate(id);
      }
    }
    if (run.cancelled) return cancelled;
    final allowedEntryIds = {
      for (final MapEntry(:key, :value) in dates.entries)
        if (value != null) key,
    };

    final notes = await _wiki.all();
    if (run.cancelled) return cancelled;
    final index = buildWikiIndex(notes, _historySettings.wikiIndexSize);
    final noteIds = {for (final n in notes) n.id};

    final model = _registry.of(target.vendor);
    final fastMode = _choice.fastModeOn;
    final system = _systemPrompt(index);
    final tools = notes.isEmpty ? const <ToolSpec>[] : const [WikiTools.spec];
    final messages = <ChatMessage>[
      ChatMessage.user(_conversationText(recent, dates)),
    ];
    final questionKey = _ids.newId();

    for (var round = 1; round <= maxRounds; round++) {
      final request = ModelRequest(
        apiKey: apiKey,
        model: target.model,
        fastMode: fastMode,
        system: system,
        messages: List.unmodifiable(messages),
        tools: tools,
      );
      final done = await _round(model, request, run, (event) {
        _recordUsage(questionKey, round, target, fastMode, index, event);
      });
      if (run.cancelled) return cancelled;
      if (done == null) {
        throw const ChatModelException(ChatModelErrorKind.network);
      }
      messages.add(done.message);
      switch (done.stop) {
        case StopKind.toolUse:
          final results = <ToolResultPart>[];
          for (final part in done.message.parts) {
            if (part is! ToolCallPart) continue;
            final result = part.name == WikiTools.readWikiName
                ? await _readWiki(part.input)
                : const ToolResult(
                    json: '{"error":"unknown_tool"}',
                    isError: true,
                  );
            results.add(
              ToolResultPart(
                callId: part.id,
                json: result.json,
                isError: result.isError,
              ),
            );
          }
          if (run.cancelled) return cancelled;
          messages.add(ChatMessage.toolResults(results));
        case StopKind.refusal:
          return const WikiDistillResult.failed(ChatFailure.refused);
        case StopKind.endTurn || StopKind.maxTokens || StopKind.other:
          final text = done.message.parts
              .whereType<TextPart>()
              .map((p) => p.text)
              .join();
          return _parse(text, allowedEntryIds, noteIds);
      }
    }
    return const WikiDistillResult.failed(ChatFailure.tooManySteps);
  }

  ChatTarget? _currentTarget() {
    final vendor = _settings.connectedVendor;
    final model = _choice.currentModel;
    if (vendor == null || model == null) return null;
    return (vendor: vendor, model: model);
  }

  /// 라운드 하나. 완료 이벤트(없으면 null)를 돌려준다. [run] 을 멈추면 구독을 끊고 null.
  Future<ModelCompleted?> _round(
    ChatModel model,
    ModelRequest request,
    _Run run,
    void Function(ModelCompleted event) onCompleted,
  ) {
    final completer = Completer<ModelCompleted?>();
    ModelCompleted? done;
    final sub = model
        .stream(request)
        .listen(
          (event) {
            if (event is ModelCompleted) {
              done = event;
              // 받는 즉시 — 청구된 라운드는 뒤가 실패해도 남는다.
              onCompleted(event);
            }
          },
          onError: (Object e, StackTrace s) {
            if (!completer.isCompleted) completer.completeError(e, s);
          },
          onDone: () {
            if (!completer.isCompleted) completer.complete(done);
          },
          cancelOnError: true,
        );
    run.onCancel = () {
      sub.cancel().ignore();
      if (!completer.isCompleted) completer.complete(null);
    };
    return completer.future.whenComplete(() => run.onCancel = null);
  }

  Future<ToolResult> _readWiki(Map<String, Object?> input) async {
    try {
      return await _wikiTools.readWiki(input);
    } catch (_) {
      return const ToolResult(json: '{"error":"tool_failed"}', isError: true);
    }
  }

  /// 살아 있는 일기의 날짜(yyyy-MM-dd). 없거나 휴지통이거나 읽기 실패면 null.
  Future<String?> _diaryDate(String entryId) async {
    try {
      return switch (await _diary.entry(entryId)) {
        Ok(:final value) when !value.isTrashed => _day.format(value.occurredAt),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }

  static final _day = DateFormat('yyyy-MM-dd');

  static String _conversationText(
    List<ChatTurnRecord> turns,
    Map<String, String?> dates,
  ) {
    final blocks = <String>[];
    for (final turn in turns) {
      final answer = turn.stopped
          ? '${turn.answer}\n${ChatSession.stoppedNote}'
          : turn.answer;
      final cited = [
        for (final id in {...turn.citedEntryIds})
          if (dates[id] case final date?) '$id($date)',
      ];
      blocks.add(
        '질문: ${turn.question}\n답: $answer'
        '${cited.isEmpty ? '' : '\n[근거 일기: ${cited.join(', ')}]'}',
      );
    }
    return '아래 대화에서 위키 후보를 뽑아라.\n\n'
        '<conversation>\n${blocks.join('\n\n')}\n</conversation>';
  }

  static const _instruction =
      '너는 사용자의 개인 기록 앱 Life Tool 의 위키 정리 도우미다.\n'
      '이 대화에서 앞으로도 쓸 사용자에 대한 사실만 후보로 뽑는다. '
      '이미 있는 메모를 고쳐야 하면 read_wiki 로 읽고 update 후보로, '
      '관련된 메모가 있으면 본문에 [[id]] 를, 근거가 된 일기가 있으면 [[일기:id]] 를 넣는다. '
      '위에 적힌 근거 일기 id 만 쓴다. 일기 문장을 옮겨 적지 않는다. 없으면 빈 목록.\n'
      '출력은 아래 형식의 JSON 하나만, 다른 글 없이:\n'
      '{"candidates":[{"action":"new"|"update","id":<update 일 때 메모 id>,'
      '"title":"…","summary":"한 줄","body":"…"}]}';

  /// 날짜 줄은 맨 끝.
  String _systemPrompt(WikiIndex index) {
    final lines = index.lines.isEmpty ? '(아직 메모 없음)' : index.lines;
    return '$_instruction\n'
        '지금 위키 색인(id · 제목 · 한 줄 요약):\n'
        '<wiki_index>\n$lines\n</wiki_index>\n'
        '오늘은 ${_day.format(_clock.now())} 이다.';
  }

  /// 모양이 어긋난 링크를 링크 글자로 맞춘다 — `[[일기: x]]` · 전각 콜론 · `[[ 3 ]]`.
  static final _looseDiaryLink = RegExp(
    r'\[\[\s*일기\s*[:：]\s*([^\s\[\]]+)\s*\]\]',
  );
  static final _looseNoteLink = RegExp(r'\[\[\s+(\d+)\s*\]\]|\[\[(\d+)\s+\]\]');

  static String _normalizeLinks(String body) => body
      .replaceAllMapped(_looseDiaryLink, (m) => wikiDiaryLinkText(m[1]!))
      .replaceAllMapped(_looseNoteLink, (m) => '[[${m[1] ?? m[2]}]]');

  static WikiDistillResult _parse(
    String text,
    Set<String> allowedEntryIds,
    Set<int> noteIds,
  ) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end < start) return const WikiDistillResult.unparsable();
    final Object? decoded;
    try {
      decoded = jsonDecode(text.substring(start, end + 1));
    } on FormatException {
      return const WikiDistillResult.unparsable();
    }
    if (decoded is! Map || decoded['candidates'] is! List) {
      return const WikiDistillResult.unparsable();
    }
    bool keep(WikiLink link) => switch (link) {
      WikiDiaryLink(:final entryId) => allowedEntryIds.contains(entryId),
      WikiNoteLink(:final id) => noteIds.contains(id),
    };
    final candidates = <WikiCandidate>[];
    for (final item in decoded['candidates'] as List) {
      if (candidates.length >= maxCandidates) break;
      if (item is! Map) continue;
      final title = item['title'];
      final summary = item['summary'];
      if (title is! String || title.trim().isEmpty) continue;
      if (summary is! String || summary.trim().isEmpty) continue;
      final rawBody = item['body'];
      final body = stripWikiLinks(
        _normalizeLinks(rawBody is String ? rawBody : ''),
        keep,
      );
      final id = _intOf(item['id']);
      candidates.add(
        item['action'] == 'update' && id != null && noteIds.contains(id)
            ? WikiCandidate.update(
                id: id,
                title: title,
                summary: summary,
                body: body,
              )
            : WikiCandidate.create(title: title, summary: summary, body: body),
      );
    }
    return WikiDistillResult.candidates(candidates);
  }

  static int? _intOf(Object? raw) => switch (raw) {
    int value => value,
    double value when value.isFinite && value == value.truncateToDouble() =>
      value.toInt(),
    String value => int.tryParse(value.trim()),
    _ => null,
  };

  /// 라운드 하나의 사용량. 기다리지 않고 오류를 삼킨다(core P10).
  void _recordUsage(
    String questionKey,
    int round,
    ChatTarget target,
    bool fastMode,
    WikiIndex index,
    ModelCompleted event,
  ) {
    final usage = event.usage;
    if (usage == null) return;
    final record = ChatUsageRecord(
      at: _clock.now(),
      questionKey: questionKey,
      vendor: target.vendor,
      model: target.model,
      fastMode: fastMode,
      purpose: ChatUsagePurpose.wikiDistill,
      round: round,
      temporary: false,
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
      cacheReadTokens: usage.cacheReadTokens,
      cacheWriteTokens: usage.cacheWriteTokens,
      reasoningTokens: usage.reasoningTokens,
      wikiIndexNotes: index.includedIds.length,
      wikiIndexChars: index.chars,
      readWikiCalls: event.message.parts
          .whereType<ToolCallPart>()
          .where((p) => p.name == WikiTools.readWikiName)
          .length,
    );
    unawaited(
      Future.sync(() => _usage.record(record)).catchError((Object _) {}),
    );
  }

  /// ChatSession 과 같은 매핑. 사진은 보내지 않으므로 imagesUnsupported 는 unknown.
  static ChatFailure _failureOf(ChatModelErrorKind kind) => switch (kind) {
    ChatModelErrorKind.invalidKey => ChatFailure.invalidKey,
    ChatModelErrorKind.rateLimited => ChatFailure.rateLimited,
    ChatModelErrorKind.overloaded => ChatFailure.overloaded,
    ChatModelErrorKind.network => ChatFailure.network,
    ChatModelErrorKind.quotaExceeded => ChatFailure.quotaExceeded,
    ChatModelErrorKind.modelUnavailable => ChatFailure.modelUnavailable,
    ChatModelErrorKind.server ||
    ChatModelErrorKind.imagesUnsupported => ChatFailure.unknown,
  };
}

/// 진행 중인 [WikiDistiller.distill] 하나.
class _Run {
  bool cancelled = false;

  /// 진행 중인 라운드의 구독 끊기.
  void Function()? onCancel;

  void cancel() {
    cancelled = true;
    onCancel?.call();
  }
}
