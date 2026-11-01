import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../../domain/chat/entity/wiki_note.dart';
import '../../../../domain/chat/repository/chat_history_repository.dart';
import '../cubit/wiki_edit_cubit.dart';
import '../cubit/wiki_edit_state.dart';
import '../open_wiki.dart';
import '../widget/diary_entry_picker_sheet.dart';
import '../widget/wiki_note_picker_sheet.dart';

/// 위키 메모 편집(스펙 §3 위키 화면 · D6 [위키에 추가]). 제목 · 한 줄 요약 · 본문 세 칸과
/// 본문 커서 자리에 링크를 넣는 [메모 링크] · [일기 링크]. 저장하면 메모 id 로 pop 한다.
///
/// 위에서 [WikiEditCubit] 를 받는다 — [openWikiEditor] 가 게이트 바깥에 둔다. 칸은
/// cubit 의 seed 로 채우므로 잠겼다 풀려 다시 만들어져도 쓰던 글이 남는다.
class WikiNoteEditPage extends StatefulWidget {
  const WikiNoteEditPage({super.key});

  @override
  State<WikiNoteEditPage> createState() => _WikiNoteEditPageState();
}

class _WikiNoteEditPageState extends State<WikiNoteEditPage> {
  late final _cubit = context.read<WikiEditCubit>();
  late final _title = TextEditingController(text: _cubit.state.seed.title);
  late final _summary = TextEditingController(text: _cubit.state.seed.summary);
  late final _body = TextEditingController(text: _cubit.state.seed.body);

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final id = await _cubit.save(
      title: _title.text,
      summary: _summary.text,
      body: _body.text,
    );
    if (!mounted) return;
    if (id != null) {
      AppSnackBar.show(context, message: l10n.walkChatWikiSaved);
      Navigator.of(context).pop(id);
    } else if (_cubit.state.error == WikiEditError.saveFailed) {
      AppSnackBar.show(
        context,
        message: l10n.walkChatWikiErrorSave,
        type: AppSnackBarType.error,
      );
    }
  }

  /// [link] 를 본문 커서 자리에 넣는다. 선택 영역이 있으면 바꿔 넣고, 커서가 없으면 끝에 붙인다.
  void _insert(String link) {
    final value = _body.value;
    final text = value.text;
    final sel = value.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    _body.value = TextEditingValue(
      text: text.replaceRange(start, end, link),
      selection: TextSelection.collapsed(offset: start + link.length),
    );
    _cubit.changed(body: _body.text);
  }

  Future<void> _linkNote() async {
    final id = await showWikiNotePicker(context, exclude: _cubit.state.seed.id);
    if (id != null && mounted) _insert(wikiNoteLinkText(id));
  }

  Future<void> _linkEntry() async {
    final suggested = await _suggested();
    if (!mounted) return;
    final id = await showDiaryEntryPicker(context, suggested: suggested);
    if (id != null && mounted) _insert(wikiDiaryLinkText(id));
  }

  /// seed 의 근거 일기 + 출처 대화 턴들의 인용 id(중복 제거, 나온 순서).
  Future<List<String>> _suggested() async {
    final seed = _cubit.state.seed;
    final ids = <String>{...seed.suggestedEntryIds};
    final source = seed.sourceConversationId;
    if (source != null) {
      try {
        final turns = await getIt<ChatHistoryRepository>().turns(source);
        for (final t in turns) {
          ids.addAll(t.citedEntryIds);
        }
      } on Object {
        // 대화를 읽지 못해도 seed 의 근거와 날짜 찾기는 쓸 수 있다.
      }
    }
    return [...ids];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<WikiEditCubit, WikiEditState>(
      buildWhen: (a, b) =>
          a.error != b.error ||
          a.saving != b.saving ||
          (a.seed.id == null) != (b.seed.id == null),
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(
            state.seed.id == null
                ? l10n.walkChatWikiNewTitle
                : l10n.walkChatWikiEditTitle,
          ),
          actions: [
            AppButton.text(
              key: const Key('wiki-edit-save'),
              // 앱 테마 버튼은 폭을 가득 채운다(`Size.fromHeight`) — 앱바 자리라 최소 크기만 푼다.
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll(Size.zero),
              ),
              label: l10n.commonSave,
              onPressed: state.saving ? null : () => unawaited(_save()),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextField(
              key: const Key('wiki-edit-title'),
              controller: _title,
              maxLength: wikiTitleMax,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.walkChatWikiFieldTitle,
                errorText: state.error == WikiEditError.emptyTitle
                    ? l10n.walkChatWikiErrorEmptyTitle
                    : null,
              ),
              onChanged: (v) => _cubit.changed(title: v),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('wiki-edit-summary'),
              controller: _summary,
              maxLength: wikiSummaryMax,
              maxLines: 1,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.walkChatWikiFieldSummary,
                helperText: l10n.walkChatWikiFieldSummaryHelp,
                errorText: state.error == WikiEditError.emptySummary
                    ? l10n.walkChatWikiErrorEmptySummary
                    : null,
              ),
              onChanged: (v) => _cubit.changed(summary: v),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('wiki-edit-body'),
              controller: _body,
              maxLength: wikiBodyMax,
              minLines: 6,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: l10n.walkChatWikiFieldBody,
                alignLabelWithHint: true,
              ),
              onChanged: (v) => _cubit.changed(body: v),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    key: const Key('wiki-edit-link-note'),
                    label: l10n.walkChatWikiLinkNote,
                    onPressed: () => unawaited(_linkNote()),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton.secondary(
                    key: const Key('wiki-edit-link-entry'),
                    label: l10n.walkChatWikiLinkEntry,
                    onPressed: () => unawaited(_linkEntry()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
