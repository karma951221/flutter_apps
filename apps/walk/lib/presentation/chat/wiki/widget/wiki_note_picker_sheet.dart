import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../../domain/chat/entity/wiki_note.dart';
import '../../../../domain/chat/repository/wiki_repository.dart';

/// 메모 고르기(제목 · 요약 포함 검색, 대소문자 무시). 고른 id 또는 null. [exclude] 는 지금 메모.
Future<int?> showWikiNotePicker(BuildContext context, {int? exclude}) =>
    showAppSheet<int>(
      context: context,
      builder: (_) => _WikiNotePicker(exclude: exclude),
    );

class _WikiNotePicker extends StatefulWidget {
  const _WikiNotePicker({required this.exclude});

  final int? exclude;

  @override
  State<_WikiNotePicker> createState() => _WikiNotePickerState();
}

class _WikiNotePickerState extends State<_WikiNotePicker> {
  late final Future<List<WikiNote>> _notes = getIt<WikiRepository>().all();
  String _query = '';

  bool _matches(WikiNote note) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return note.title.toLowerCase().contains(q) ||
        note.summary.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<WikiNote>>(
      future: _notes,
      builder: (context, snapshot) {
        final notes = snapshot.data;
        return AppSheetScaffold.draggable(
          title: l10n.walkChatWikiPickNoteTitle,
          initialSize: 0.75,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: TextField(
                key: const Key('wiki-pick-note-search'),
                decoration: InputDecoration(
                  hintText: l10n.walkChatWikiPickNoteSearch,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            if (snapshot.hasError)
              AppPlaceholder(
                icon: Icons.error_outline,
                message: l10n.walkChatWikiLoadFailed,
              )
            else if (notes == null)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: AppLoading(),
              )
            else
              for (final note in notes)
                if (note.id != widget.exclude && _matches(note))
                  AppListTile(
                    key: Key('wiki-pick-note-${note.id}'),
                    title: Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      note.summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.pop(context, note.id),
                  ),
          ],
        );
      },
    );
  }
}
