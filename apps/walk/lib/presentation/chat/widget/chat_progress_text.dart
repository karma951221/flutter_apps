import 'package:characters/characters.dart';
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
  StepTool() => _resultText(l10n, step) ?? _toolLabel(l10n, locale, step),
  StepWriting() => l10n.walkChatPhaseWriting,
  StepStopped() => l10n.walkChatStopped,
};

/// 펼친 단계 목록의 한 줄(앞의 `·` 제외). 도구는 "라벨 — 결과", 답은 "답 쓰기".
String chatProgressTimelineText(
  AppLocalizations l10n,
  String locale,
  ChatProgressStep step,
) => switch (step) {
  StepTool() => switch (_resultText(l10n, step)) {
    // 쓰기는 결과 문구가 이름까지 든다 — "파일 저장 중 · a.md — 저장함 · a.md" 대신 결과만.
    final result? when _isWrite(step.kind) => result,
    final result? => '${_toolLabel(l10n, locale, step)} — $result',
    null => _toolLabel(l10n, locale, step),
  },
  StepWriting() => l10n.walkChatPhaseWritingDone,
  _ => chatProgressStepText(l10n, locale, step),
};

/// 접힌 요약 — "기록 3번 찾아봄 · 9초" · "9초" · "멈춤 · 기록 1번 찾아봄 · 4초".
/// 웹 검색 · 파일 쓰기는 기록을 찾아본 수에 넣지 않는다([ChatProgress.toolCalls]).
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
    // 쓰기는 "승인 기다리는 중 · 이름" → "파일 저장 중 · 이름". 자세히(괄호)는 없다.
    ChatToolKind.writeFile ||
    ChatToolKind.editFile ||
    ChatToolKind.deleteFile => _writeLabel(l10n, step),
    ChatToolKind.other => l10n.walkChatToolOther,
  };
  final detail = _detail(l10n, locale, step.kind, step.input);
  return detail == null ? label : l10n.walkChatToolDetail(label, detail);
}

bool _isWrite(ChatToolKind kind) =>
    kind == ChatToolKind.writeFile ||
    kind == ChatToolKind.editFile ||
    kind == ChatToolKind.deleteFile;

/// 쓰기 도구의 지금 라벨 — 승인을 기다리면 "승인 기다리는 중", 아니면 실행 라벨. 이름을 모르면 이름 없이.
String _writeLabel(AppLocalizations l10n, StepTool step) {
  final name = _shortName(step.input?.name);
  if (step.awaitingApproval) {
    return name == null
        ? l10n.walkChatToolAwaitingApproval
        : l10n.walkChatToolAwaitingApprovalNamed(name);
  }
  return switch ((step.kind, name)) {
    (ChatToolKind.editFile, final n?) => l10n.walkChatToolEditFileNamed(n),
    (ChatToolKind.editFile, null) => l10n.walkChatToolEditFile,
    (ChatToolKind.deleteFile, final n?) => l10n.walkChatToolDeleteFileNamed(n),
    (ChatToolKind.deleteFile, null) => l10n.walkChatToolDeleteFile,
    (_, final n?) => l10n.walkChatToolWriteFileNamed(n),
    (_, null) => l10n.walkChatToolWriteFile,
  };
}

/// 진행 줄의 파일 이름 최대 글자 수(grapheme). 넘으면 이만큼 + '…'.
const _nameMaxChars = 20;

/// 20자 넘으면 20자 + '…'. 이미 줄인 이름은 그대로다. 비면 null.
String? _shortName(String? name) {
  if (name == null || name.isEmpty) return null;
  final chars = name.characters;
  return chars.length > _nameMaxChars
      ? '${chars.take(_nameMaxChars).string}…'
      : name;
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

/// 결과 문구. 결과가 없거나 읽기 도구 오류면 null — 라벨 그대로 둔다(오류 문구 없음).
/// 사용자가 거절한 쓰기는 "거절함", 성공한 쓰기는 "저장함 · 이름" 류, 오류로 끝난 쓰기
/// (이미 있음 · 이름 규칙 · 바뀜 · 실패)는 "저장 못 함 · 이름" — "파일 저장 중" 에 머물지 않게.
String? _resultText(AppLocalizations l10n, StepTool step) {
  final result = step.result;
  if (result == null) return null;
  if (result.declined) return l10n.walkChatToolDeclined;
  if (result.isError) {
    if (!_isWrite(result.kind)) return null;
    return switch (_shortName(step.input?.name)) {
      final name? => l10n.walkChatToolWriteFailedNamed(name),
      null => l10n.walkChatToolWriteFailed,
    };
  }
  if (_isWrite(result.kind)) {
    final name = _shortName(step.input?.name) ?? '';
    return switch (result.kind) {
      ChatToolKind.editFile => l10n.walkChatToolEdited(name),
      ChatToolKind.deleteFile => l10n.walkChatToolDeleted(name),
      _ => l10n.walkChatToolWrote(name),
    };
  }
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
    // 쓰기 도구는 위에서 다뤘다.
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
