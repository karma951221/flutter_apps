import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../../domain/chat/chat_history_settings.dart';
import '../../../../domain/chat/chat_settings.dart';
import '../../../../domain/chat/chat_vendor.dart';
import '../../../../domain/chat/entity/wiki_note.dart';
import '../../../../domain/chat/repository/wiki_repository.dart';
import '../../../../domain/chat/usecase/chat_session.dart';
import '../../../settings/widget/wiki_index_size_sheet.dart';
import '../../widget/chat_vendor_icon.dart';
import '../cubit/wiki_cubit.dart';
import '../cubit/wiki_edit_state.dart';
import '../cubit/wiki_state.dart';
import '../open_wiki.dart';

enum _PageAction { deleteAll }

/// 위키 메모 목록(스펙 §3 위키 화면). 행을 누르면 메모 화면 — 거기서 [대화 보기]를 고르면
/// 그 대화 id 로 pop 한다. [openWikiPage] 로 연다(잠금 아래).
///
/// 목록은 끝 가까이 스크롤하면 다음 쪽을 읽는다. 앱바 검색 아이콘을 누르면 제목 자리가
/// 검색칸이 되고(제목 · 요약 · 본문), 뒤로가기 · 닫기는 검색만 닫는다.
class WikiPage extends StatelessWidget {
  const WikiPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        WikiCubit(getIt<WikiRepository>(), getIt<ChatHistorySettings>()),
    child: const _WikiView(),
  );
}

class _WikiView extends StatefulWidget {
  const _WikiView();

  @override
  State<_WikiView> createState() => _WikiViewState();
}

class _WikiViewState extends State<_WikiView> {
  final _searchText = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchText.dispose();
    super.dispose();
  }

  void _openSearch() => setState(() => _searching = true);

  void _closeSearch() {
    _searchText.clear();
    context.read<WikiCubit>().setQuery('');
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<WikiCubit, WikiState>(
    builder: (context, state) {
      final l10n = AppLocalizations.of(context);
      return PopScope(
        canPop: !_searching,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _closeSearch();
        },
        child: Scaffold(
          appBar: _searching
              ? _searchBar(context, l10n)
              : _titleBar(context, state, l10n),
          body: _body(context, state, l10n),
        ),
      );
    },
  );

  PreferredSizeWidget _titleBar(
    BuildContext context,
    WikiState state,
    AppLocalizations l10n,
  ) => AppBar(
    title: Text(l10n.walkChatWikiTitle),
    actions: [
      if (state.total > 0)
        IconButton(
          key: const Key('wiki-search'),
          icon: const Icon(Icons.search),
          tooltip: l10n.walkChatWikiSearch,
          onPressed: _openSearch,
        ),
      IconButton(
        key: const Key('wiki-add'),
        icon: const Icon(Icons.add),
        tooltip: l10n.walkChatWikiAdd,
        onPressed: () => unawaited(
          openWikiEditor(
            context,
            const WikiEditSeed(title: '', summary: '', body: ''),
          ),
        ),
      ),
      AppOverflowMenu<_PageAction>(
        items: [
          if (state.total > 0)
            AppOverflowMenuItem(
              value: _PageAction.deleteAll,
              label: l10n.walkChatWikiDeleteAll,
              icon: Icons.delete_sweep_outlined,
              isDestructive: true,
            ),
        ],
        onSelected: (_) => _deleteAll(context, state.total),
      ),
    ],
  );

  /// 일기 검색과 같은 모양 — 테두리 없는 칸이 제목 자리에 든다.
  PreferredSizeWidget _searchBar(BuildContext context, AppLocalizations l10n) =>
      AppBar(
        title: TextField(
          key: const Key('wiki-search-field'),
          controller: _searchText,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.walkChatWikiSearchHint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: context.read<WikiCubit>().setQuery,
        ),
        actions: [
          IconButton(
            key: const Key('wiki-search-close'),
            icon: const Icon(Icons.close),
            tooltip: l10n.walkChatWikiSearchClose,
            onPressed: _closeSearch,
          ),
        ],
      );

  Widget _body(BuildContext context, WikiState state, AppLocalizations l10n) {
    if (state.loading) return const AppLoading();
    if (state.failed && state.notes.isEmpty) {
      return AppPlaceholder(
        icon: Icons.error_outline,
        message: l10n.walkChatWikiLoadFailed,
      );
    }
    if (state.noResults) {
      return AppPlaceholder(
        icon: Icons.search_off,
        message: l10n.walkChatWikiSearchNoResults(state.searched),
      );
    }
    if (state.notes.isEmpty && state.searched.isEmpty) {
      return Column(
        children: [
          const _Notice(),
          Expanded(
            child: AppPlaceholder(
              icon: Icons.menu_book_outlined,
              message: l10n.walkChatWikiEmpty,
            ),
          ),
        ],
      );
    }
    final cubit = context.read<WikiCubit>();
    final notIndexed = state.searched.isEmpty ? state.notIndexed : 0;
    // 한 쪽 안에 다 들어가면 끝 표시는 군더더기 — 더 읽어 본 적이 있을 때만.
    final footer =
        state.hasMore ||
        state.loadingMore ||
        state.notes.length > cubit.pageSize;
    final head = [
      if (state.searched.isEmpty) const _Notice(),
      if (notIndexed > 0)
        AppListTile(
          key: const Key('wiki-not-indexed'),
          title: Text(l10n.walkChatWikiNotIndexed(notIndexed)),
          onTap: () => _pickSize(context, state),
        ),
    ];
    final count = head.length + state.notes.length + (footer ? 1 : 0);
    return AppLoadMoreListener(
      onLoadMore: cubit.loadMore,
      child: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: count,
        itemBuilder: (context, i) {
          if (i < head.length) return head[i];
          final n = i - head.length;
          if (n < state.notes.length) {
            final note = state.notes[n];
            return _NoteRow(
              note: note,
              indexed: state.indexedIds.contains(note.id),
            );
          }
          return AppListFooter(
            isLoadingMore: state.loadingMore,
            canLoadMore: state.hasMore,
          );
        },
      ),
    );
  }

  /// 색인 크기 시트 — 고르면 저장하고, 돌아오면 색인 표시를 다시 계산한다.
  Future<void> _pickSize(BuildContext context, WikiState state) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<WikiCubit>();
    final settings = getIt<ChatHistorySettings>();
    final picked = await showWikiIndexSizeSheet(
      context,
      current: state.size,
      noteCount: state.total,
      indexChars: state.indexChars,
    );
    if (picked != null) {
      try {
        await settings.setWikiIndexSize(picked);
      } on Object {
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.walkChatWikiIndexSizeFailed,
            type: AppSnackBarType.error,
          );
        }
      }
    }
    if (!cubit.isClosed) cubit.refreshSize();
  }

  Future<void> _deleteAll(BuildContext context, int count) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<WikiCubit>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkChatWikiDeleteAllTitle,
      content: l10n.walkChatWikiDeleteAllBody(count),
      confirmLabel: l10n.walkChatWikiDeleteAllConfirm,
    );
    if (!confirmed) return;
    try {
      await cubit.deleteAll();
    } on Object {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: l10n.walkChatWikiDeleteFailed,
          type: AppSnackBarType.error,
        );
      }
    }
  }
}

/// 맨 위 안내 한 줄 — 색인 · 본문이 어느 벤더로 가는지.
class _Notice extends StatelessWidget {
  const _Notice();

  /// 다음 질문의 벤더. 모델 목록이 없으면(target null) 연결 벤더로.
  static ChatVendor _vendor() =>
      getIt<ChatSession>().target?.vendor ??
      getIt<ChatSettings>().connectedVendor ??
      ChatVendor.anthropic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppFootnote(
      l10n.walkChatWikiNotice(chatVendorName(l10n, _vendor())),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    );
  }
}

/// 메모 한 행 — 제목 · 요약 · 수정일, 색인 밖이면 표시.
class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note, required this.indexed});

  final WikiNote note;
  final bool indexed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = DateFormat.yMMMd(l10n.localeName).format(note.updatedAt);
    return AppListTile(
      key: Key('wiki-note-${note.id}'),
      title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${note.summary}\n${l10n.walkChatWikiUpdated(date)}'),
      trailing: indexed
          ? null
          : Icon(
              Icons.visibility_off_outlined,
              semanticLabel: l10n.walkChatWikiNotIndexedRow,
            ),
      onTap: () async {
        final id = await openWikiNote(context, note.id);
        if (id != null && context.mounted) Navigator.of(context).pop(id);
      },
    );
  }
}
