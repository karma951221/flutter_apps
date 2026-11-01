import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/chat_history_settings.dart';

/// 위키 색인 크기를 고르는 시트. 고른 크기 또는 null.
/// 위쪽에 "지금 위키 n개 · 색인 약 m자"([current] 크기 기준).
Future<WikiIndexSize?> showWikiIndexSizeSheet(
  BuildContext context, {
  required WikiIndexSize current,
  required int noteCount,
  required int indexChars,
}) => showModalBottomSheet<WikiIndexSize>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _WikiIndexSizeSheet(
    current: current,
    noteCount: noteCount,
    indexChars: indexChars,
  ),
);

/// 크기 이름(설정 행의 trailing 과 같이 쓴다).
String wikiIndexSizeLabel(AppLocalizations l10n, WikiIndexSize size) =>
    switch (size) {
      WikiIndexSize.small => l10n.walkChatWikiIndexSizeSmall,
      WikiIndexSize.standard => l10n.walkChatWikiIndexSizeStandard,
      WikiIndexSize.large => l10n.walkChatWikiIndexSizeLarge,
      WikiIndexSize.all => l10n.walkChatWikiIndexSizeAll,
    };

class _WikiIndexSizeSheet extends StatelessWidget {
  const _WikiIndexSizeSheet({
    required this.current,
    required this.noteCount,
    required this.indexChars,
  });

  final WikiIndexSize current;
  final int noteCount;
  final int indexChars;

  /// 상한 한 줄 + 안내(기본은 안내 없음).
  static String _detail(
    AppLocalizations l10n,
    NumberFormat number,
    WikiIndexSize size,
  ) {
    final maxNotes = size.maxNotes;
    final chars = number.format(size.maxChars);
    final limit = maxNotes == null
        ? l10n.walkChatWikiIndexSizeAllDetail(chars)
        : l10n.walkChatWikiIndexSizeDetail(number.format(maxNotes), chars);
    final note = switch (size) {
      WikiIndexSize.small => l10n.walkChatWikiIndexSizeSmallNote,
      WikiIndexSize.standard => null,
      WikiIndexSize.large => l10n.walkChatWikiIndexSizeLargeNote,
      WikiIndexSize.all => l10n.walkChatWikiIndexSizeAllNote,
    };
    return note == null ? limit : '$limit\n$note';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final number = NumberFormat.decimalPattern(l10n.localeName);
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Text(
                l10n.walkChatWikiIndexSize,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Text(
                l10n.walkChatWikiIndexSizeCurrent(
                  noteCount,
                  number.format(indexChars),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final size in WikiIndexSize.values)
              AppListTile(
                key: Key('wiki-size-${size.name}'),
                title: Text(wikiIndexSizeLabel(l10n, size)),
                subtitle: Text(_detail(l10n, number, size)),
                trailing: size == current
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(context, size),
              ),
          ],
        ),
      ),
    );
  }
}
