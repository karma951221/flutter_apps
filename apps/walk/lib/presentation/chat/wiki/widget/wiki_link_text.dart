import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../../domain/chat/entity/wiki_note.dart';
import '../../../../domain/diary/entity/diary_entry.dart';
import '../../widget/cited_entry_chip.dart';

/// 본문을 글 + 링크 칩으로. 메모 칩은 제목, 일기 칩은 근거 칩([CitedEntryChip])과 같은 모양.
/// 대상이 없으면 흐린(onSurface 38%) 비활성 칩 '지워진 메모' · '지워진 일기'(D15) — 본문은 그대로 둔다.
class WikiLinkText extends StatelessWidget {
  const WikiLinkText({
    required this.body,
    required this.notes,
    required this.entries,
    required this.onOpenNote,
    required this.onOpenEntry,
    super.key,
  });

  final String body;

  /// 본문이 가리키는 메모 중 남아 있는 것.
  final Map<int, WikiNote> notes;

  /// 본문이 가리키는 일기 중 살아 있는 것(휴지통 제외).
  final Map<String, DiaryEntry> entries;

  /// null 이면 칩을 누를 수 없다(후보 시트 — 시트 위에서 다른 화면을 열지 않는다).
  final ValueChanged<int>? onOpenNote;
  final ValueChanged<String>? onOpenEntry;

  /// 지워진 대상 칩의 흐림 — Material 의 비활성 글자와 같은 값.
  static const missingOpacity = 0.38;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (final segment in parseWikiBody(body))
            switch (segment) {
              WikiTextSegment(:final text) => TextSpan(text: text),
              WikiLinkSegment(:final link) => WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _chip(context, link),
              ),
            },
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, WikiLink link) {
    final l10n = AppLocalizations.of(context);
    switch (link) {
      case WikiNoteLink(:final id):
        final note = notes[id];
        if (note == null) {
          return _MissingChip(label: l10n.walkChatWikiDeletedNote);
        }
        final open = onOpenNote;
        // 누를 수 없을 때도 살아 있는 링크는 흐리지 않는다 — 흐림은 지워진 대상만.
        if (open == null) {
          return Chip(
            key: Key('wiki-link-note-$id'),
            avatar: const Icon(Icons.description_outlined),
            label: Text(note.title),
          );
        }
        return ActionChip(
          key: Key('wiki-link-note-$id'),
          avatar: const Icon(Icons.description_outlined),
          label: Text(note.title),
          onPressed: () => open(id),
        );
      case WikiDiaryLink(:final entryId):
        final entry = entries[entryId];
        if (entry == null) {
          return _MissingChip(label: l10n.walkChatWikiDeletedEntry);
        }
        return CitedEntryChip(
          key: Key('wiki-link-entry-$entryId'),
          entry: entry,
          onOpen: switch (onOpenEntry) {
            final open? => () => open(entryId),
            null => null,
          },
        );
    }
  }
}

/// 누를 수 없는 흐린 칩.
class _MissingChip extends StatelessWidget {
  const _MissingChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final faded = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: WikiLinkText.missingOpacity);
    return ActionChip(
      avatar: Icon(Icons.link_off, color: faded),
      label: Text(label, style: TextStyle(color: faded)),
      onPressed: null,
    );
  }
}
