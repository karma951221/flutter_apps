import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/tool/tool_summary.dart';
import '../cubit/chat_progress.dart';

/// 지금 단계 문구. 도구는 "라벨(자세히)", 결과가 있으면 결과 문구.
String chatProgressStepText(
  AppLocalizations l10n,
  String locale,
  ChatProgressStep step,
) => switch (step) {
  StepSending() => l10n.walkChatPhaseSending,
  StepThinking() => l10n.walkChatPhaseThinking,
  StepNote(:final text) => text,
  StepTool() =>
    _resultText(l10n, step.result) ?? _toolLabel(l10n, locale, step),
  StepWriting() => l10n.walkChatPhaseWriting,
  StepStopped() => l10n.walkChatStopped,
};

/// 펼친 단계 목록의 한 줄(앞의 `·` 제외). 도구는 "라벨 — 결과", 답은 "답 쓰기".
String chatProgressTimelineText(
  AppLocalizations l10n,
  String locale,
  ChatProgressStep step,
) => switch (step) {
  StepTool() => switch (_resultText(l10n, step.result)) {
    final result? => '${_toolLabel(l10n, locale, step)} — $result',
    null => _toolLabel(l10n, locale, step),
  },
  StepWriting() => l10n.walkChatPhaseWritingDone,
  _ => chatProgressStepText(l10n, locale, step),
};

/// 접힌 요약 — "기록 3번 찾아봄 · 9초" · "9초" · "멈춤 · 기록 1번 찾아봄 · 4초".
/// 웹 검색은 기록을 찾아본 수에 넣지 않는다([ChatProgress.toolCalls]).
String chatProgressSummaryText(AppLocalizations l10n, ChatProgress progress) {
  final calls = progress.toolCalls;
  final parts = [
    if (progress.stopped) l10n.walkChatStopped,
    if (calls > 0) l10n.walkChatProgressLookups(calls),
    l10n.walkChatProgressElapsed(progress.elapsedSeconds),
  ];
  return parts.reduce(l10n.walkChatProgressJoin);
}

String _toolLabel(AppLocalizations l10n, String locale, StepTool step) {
  final label = switch (step.kind) {
    ChatToolKind.searchDiary => l10n.walkChatToolSearchDiary,
    ChatToolKind.viewPhotos => l10n.walkChatToolViewPhotos,
    ChatToolKind.diaryIndex => l10n.walkChatToolDiaryIndex,
    ChatToolKind.dailySteps => l10n.walkChatToolDailySteps,
    ChatToolKind.wakeRecords => l10n.walkChatToolWakeRecords,
    ChatToolKind.wiki => l10n.walkChatToolReadWiki,
    ChatToolKind.webSearch => l10n.walkChatToolWebSearch,
    ChatToolKind.listFiles => l10n.walkChatToolListFiles,
    // "파일 읽는 중 · 이름" — 이름이 라벨에 붙으므로 자세히(괄호)는 없다.
    ChatToolKind.readFile => switch (step.input?.name) {
      final name? => l10n.walkChatToolReadFileNamed(name),
      null => l10n.walkChatToolReadFile,
    },
    // 쓰기 도구 라벨은 승인 · 진행 줄 작업에서 따로 붙인다 — 그때까지는 알 수 없는 도구처럼.
    ChatToolKind.writeFile ||
    ChatToolKind.editFile ||
    ChatToolKind.deleteFile ||
    ChatToolKind.other => l10n.walkChatToolOther,
  };
  final detail = _detail(l10n, locale, step.kind, step.input);
  return detail == null ? label : l10n.walkChatToolDetail(label, detail);
}

/// 기간(걸음은 날 수) · 검색어. 둘 다 없으면 null.
String? _detail(
  AppLocalizations l10n,
  String locale,
  ChatToolKind kind,
  ToolInputSummary? input,
) {
  if (input == null) return null;
  final from = input.from;
  final to = input.to;
  final String? range;
  if (from != null && to != null && kind == ChatToolKind.dailySteps) {
    final days = _dateOnly(to).difference(_dateOnly(from)).inDays.abs() + 1;
    range = l10n.walkChatToolDays(days);
  } else if (from != null && to != null) {
    final format = DateFormat.MMMd(locale);
    range = _sameDay(from, to)
        ? format.format(from)
        : l10n.walkChatToolRange(format.format(from), format.format(to));
  } else if ((from ?? to) case final day?) {
    range = DateFormat.MMMd(locale).format(day);
  } else {
    range = null;
  }
  final query = switch (input.query) {
    final q? when q.isNotEmpty => l10n.walkChatToolQuery(q),
    _ => null,
  };
  return switch ((range, query)) {
    (final r?, final q?) => l10n.walkChatProgressJoin(r, q),
    (final r?, null) => r,
    (null, final q?) => q,
    (null, null) => null,
  };
}

/// 결과 문구. 결과가 없거나 오류면 null — 라벨 그대로 둔다(오류 문구 없음).
String? _resultText(AppLocalizations l10n, ToolSummary? result) {
  if (result == null || result.isError) return null;
  final count = result.count;
  // 빈 작업 폴더는 "찾은 기록 없음" 이 아니라 폴더가 비었다고 말한다.
  if (count == 0 && result.kind == ChatToolKind.listFiles) {
    return l10n.walkChatToolNoFiles;
  }
  if (count == 0) return l10n.walkChatToolFoundNone;
  return switch (result.kind) {
    ChatToolKind.searchDiary => l10n.walkChatToolFoundEntries(count),
    ChatToolKind.viewPhotos => l10n.walkChatToolFoundPhotos(count),
    ChatToolKind.diaryIndex => l10n.walkChatToolFoundIndex(count),
    ChatToolKind.dailySteps => l10n.walkChatToolFoundSteps(count),
    ChatToolKind.wakeRecords => l10n.walkChatToolFoundWake(count),
    ChatToolKind.wiki => l10n.walkChatToolFoundWiki(count),
    ChatToolKind.listFiles => l10n.walkChatToolFoundFiles(count),
    // 웹 검색은 결과를 세지 않는다 · 파일 읽기는 늘 한 건이라 이름 라벨 그대로 ·
    // 알 수 없는 도구는 개수 단위를 모른다 — 라벨 그대로.
    ChatToolKind.webSearch ||
    ChatToolKind.readFile ||
    ChatToolKind.writeFile ||
    ChatToolKind.editFile ||
    ChatToolKind.deleteFile ||
    ChatToolKind.other => null,
  };
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
