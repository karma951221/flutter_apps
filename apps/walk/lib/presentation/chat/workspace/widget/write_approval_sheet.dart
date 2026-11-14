import 'dart:convert';

import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../../domain/chat/tool/write_plan.dart';
import '../../../settings/widget/diary_storage_section.dart';
import '../format/reveal_invisible.dart';

/// 쓰기 승인 시트를 띄운다(스펙 §3). [저장] · [고치기] · [지우기] → [onApprove],
/// [거절] · 밖 누름 · 뒤로 → [onDecline]. 둘 중 하나만, 한 번 부른다.
///
/// [dismiss] 가 true 가 되면(기다리던 쓰기가 멈춤 · 대화 전환 · 실패로 끝남) 아무것도 부르지 않고
/// 닫는다 — 이미 끝난 쓰기에 답하지 않는다.
Future<void> showWriteApprovalSheet(
  BuildContext context, {
  required WritePlan plan,
  required String assistant,
  required VoidCallback onApprove,
  required VoidCallback onDecline,
  ValueListenable<bool>? dismiss,
}) async {
  var answered = false;
  // 버튼 · 밖 누름 · dismiss 중 먼저 온 것 하나만.
  bool answer() {
    if (answered) return false;
    answered = true;
    return true;
  }

  BuildContext? sheet;
  // 시트 경로만 닫는다 — 위에 다른 것이 얹혀 있어도 아래 화면은 건드리지 않는다.
  void close() {
    final c = sheet;
    if (c == null || !c.mounted) return;
    final route = ModalRoute.of(c);
    if (route == null || !route.isActive) return;
    if (route.isCurrent) {
      Navigator.of(c).pop();
    } else {
      Navigator.of(c).removeRoute(route);
    }
  }

  void onSignal() {
    if ((dismiss?.value ?? false) && answer()) close();
  }

  if (dismiss?.value ?? false) return;
  dismiss?.addListener(onSignal);
  try {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        sheet = sheetContext;
        // 처음 그리기 전에 dismiss 가 왔다 — 그리자마자 닫는다.
        if (answered) {
          WidgetsBinding.instance.addPostFrameCallback((_) => close());
        }
        return WriteApprovalSheet(
          plan: plan,
          assistant: assistant,
          onApprove: () {
            if (!answer()) return;
            onApprove();
            close();
          },
          onDecline: () {
            if (!answer()) return;
            onDecline();
            close();
          },
        );
      },
    );
  } finally {
    dismiss?.removeListener(onSignal);
  }
  // 밖 누름 · 뒤로 · 잠금으로 닫혔다.
  if (answer()) onDecline();
}

/// 쓰기 하나의 승인 시트 본문. 경로 · 크기 · 내용을 글자 그대로(렌더링 없이, 보이지 않는 글자를
/// 드러내어) 보이고, 긴 내용은 시트 안에서 세로로 스크롤한다. 버튼은 한 번만 눌린다.
class WriteApprovalSheet extends StatefulWidget {
  const WriteApprovalSheet({
    required this.plan,
    required this.assistant,
    required this.onApprove,
    required this.onDecline,
    super.key,
  });

  final WritePlan plan;

  /// 쓰려는 쪽 이름(Claude · GPT).
  final String assistant;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  @override
  State<WriteApprovalSheet> createState() => _WriteApprovalSheetState();
}

class _WriteApprovalSheetState extends State<WriteApprovalSheet> {
  bool _decided = false;

  void _decide(VoidCallback action) {
    if (_decided) return;
    setState(() => _decided = true);
    action();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final plan = widget.plan;
    final who = widget.assistant;
    final (title, intent, approveLabel) = switch (plan) {
      WriteCreate() => (
        l10n.walkChatWriteTitleCreate,
        l10n.walkChatWriteIntentCreate(who),
        l10n.walkChatWriteSave,
      ),
      WriteOverwrite() => (
        l10n.walkChatWriteTitleOverwrite,
        l10n.walkChatWriteIntentOverwrite(who),
        l10n.walkChatWriteSave,
      ),
      WriteEdit() => (
        l10n.walkChatWriteTitleEdit,
        l10n.walkChatWriteIntentEdit(who),
        l10n.walkChatWriteEdit,
      ),
      WriteDelete() => (
        l10n.walkChatWriteTitleDelete,
        l10n.walkChatWriteIntentDelete(who),
        l10n.walkChatWriteDelete,
      ),
    };
    final sizeBytes = switch (plan) {
      WriteCreate(:final content) ||
      WriteOverwrite(:final content) ||
      WriteEdit(:final content) => utf8.encode(content).length,
      WriteDelete(:final sizeBytes) => sizeBytes,
    };
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final destructive = plan is WriteDelete;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            // 실제 상대 경로 그대로 — 줄이지 않고, 보이지 않는 글자는 드러낸다.
            Text(
              '${revealInvisible(plan.path)} · ${DiaryStorageSection.formatBytes(sizeBytes)}',
              style: muted,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(intent, style: theme.textTheme.bodyMedium),
            if (plan case WriteOverwrite(:final previous))
              Text(
                l10n.walkChatWriteReplaces(previous.runes.length),
                style: muted,
              ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _body(context, l10n, plan),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: l10n.walkChatWriteDecline,
                    onPressed: _decided
                        ? null
                        : () => _decide(widget.onDecline),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton.primary(
                    label: approveLabel,
                    style: destructive
                        ? FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                          )
                        : null,
                    onPressed: _decided
                        ? null
                        : () => _decide(widget.onApprove),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    AppLocalizations l10n,
    WritePlan plan,
  ) => switch (plan) {
    WriteCreate(:final content) ||
    WriteOverwrite(:final content) => [_TextBox(text: content)],
    WriteEdit(:final previous, :final oldText, :final newText) => [
      if (_editContext(previous, oldText) case (:final before, :final after))
        ..._labelled(
          context,
          l10n.walkChatWriteContext,
          _ContextBox(before: before, after: after),
        ),
      ..._labelled(context, l10n.walkChatWriteOldText, _TextBox(text: oldText)),
      const SizedBox(height: AppSpacing.sm),
      ..._labelled(context, l10n.walkChatWriteNewText, _TextBox(text: newText)),
    ],
    WriteDelete(:final previous) => [
      _TextBox(text: _head(previous)),
      if (_moreLines(previous) case final more when more > 0)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            l10n.walkChatWriteMoreLines(more),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
    ],
  };

  List<Widget> _labelled(BuildContext context, String label, Widget box) => [
    Text(label, style: Theme.of(context).textTheme.labelMedium),
    const SizedBox(height: AppSpacing.xs),
    box,
  ];
}

/// 지우기 미리 보기 줄 수.
const _previewLines = 20;

String _head(String text) => text.split('\n').take(_previewLines).join('\n');

int _moreLines(String text) => '\n'.allMatches(text).length + 1 - _previewLines;

/// [previous] 에서 [oldText] 가 처음 나오는 곳 앞뒤 한 줄씩의 맥락. 앞은 그 앞 줄과 바뀌는 곳이 든
/// 줄의 앞부분, 뒤는 그 줄의 뒷부분과 다음 줄. 없으면(준비 때 검증했으니 보통 없다) null.
({String before, String after})? _editContext(String previous, String oldText) {
  final start = previous.indexOf(oldText);
  if (oldText.isEmpty || start < 0) return null;
  final end = start + oldText.length;
  int lineStart(int i) => i <= 0 ? 0 : previous.lastIndexOf('\n', i - 1) + 1;
  int lineEnd(int i) {
    final n = previous.indexOf('\n', i);
    return n < 0 ? previous.length : n;
  }

  final own = lineStart(start);
  final from = own == 0 ? 0 : lineStart(own - 1);
  final ownEnd = lineEnd(end);
  final to = ownEnd >= previous.length ? previous.length : lineEnd(ownEnd + 1);
  return (
    before: previous.substring(from, start),
    after: previous.substring(end, to),
  );
}

/// 고정폭 글꼴 이름. Android 시스템 고정폭 글꼴로 풀린다.
const _monospace = 'monospace';

TextStyle? _monoStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: _monospace);

BoxDecoration _boxDecoration(BuildContext context) => BoxDecoration(
  color: Theme.of(context).colorScheme.surfaceContainerHighest,
  borderRadius: AppRadius.smAll,
);

/// 글자 그대로의 고정폭 상자. 마크다운 · 링크를 그리지 않고, 고를 수 있고, 긴 줄은 줄바꿈한다.
class _TextBox extends StatelessWidget {
  const _TextBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: _boxDecoration(context),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: SelectableText(revealInvisible(text), style: _monoStyle(context)),
    ),
  );
}

/// 고치기 맥락 상자 — 바뀌는 자리는 `⋯` 로 표시한다.
class _ContextBox extends StatelessWidget {
  const _ContextBox({required this.before, required this.after});

  final String before;
  final String after;

  @override
  Widget build(BuildContext context) {
    final mark = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.bold,
    );
    return DecoratedBox(
      decoration: _boxDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: SelectableText.rich(
          TextSpan(
            style: _monoStyle(context),
            children: [
              TextSpan(text: revealInvisible(before)),
              TextSpan(text: '⋯', style: mark),
              TextSpan(text: revealInvisible(after)),
            ],
          ),
        ),
      ),
    );
  }
}
